/*
 * @file       mobile_ride_provider.dart
 * @brief      Orchestrates rental workflows over MQTT (START / PAUSE / RESUME /
 *             STOP / END / warnings) and exposes UI-friendly state.
 */

/* Imports ------------------------------------------------------------ */
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/feature_conf.dart';
import '../config/mqtt_config.dart';
import '../models/error_codes.dart';
import '../models/mobile_user_profile.dart';
import '../models/pricing_config.dart';
import '../models/rental_bill.dart';
import '../services/mqtt_service.dart';
import '../services/protocol_codec.dart';
import '../services/user_wire_id.dart';
import 'mobile_telemetry_provider.dart';

/* Constants ---------------------------------------------------------- */
const int kDefaultPricePerHour = 10000;
const int kDefaultDepositAmount = 10000;
const int kDefaultMinimumRequiredBalance = 20000;
const int kDefaultLowBatteryThreshold = 20;

/* Enums -------------------------------------------------------------- */

enum RentalPhase { idle, starting, running, paused, stopping, ended }

/* Typedef / Function types ------------------------------------------ */
/* Public classes ----------------------------------------------------- */

class MobileRideProvider extends ChangeNotifier {
  MobileRideProvider(this._mqtt, {MobileTelemetryProvider? telemetry})
    : _telemetry = telemetry;

  /* --- private fields ------------------------------------------ */
  final MqttService _mqtt;
  final MobileTelemetryProvider? _telemetry;
  StreamSubscription<ProtocolMessage>? _webAppSub;
  Timer? _timer;
  Timer? _pauseTimeoutTimer;
  String? _uid;
  String? _wireUserId;
  String? _bikeId;
  DateTime? _startedAt;
  // Total bill = (initial hours + extra hours) * pricePerHour
  int _consumedAtPhaseStart = 0;
  int _selectedRentalHours = 1;

  /* --- public fields ------------------------------------------- */
  RentalPhase phase = RentalPhase.idle;
  RentalBill? lastBill;
  String? lastError;
  String?
  warning; /* WARN_LOW_BALANCE / WARN_OUT_OF_BALANCE / WARN_DEBT / RENTAL_NOTI_LIMIT */
  int debtAmount = 0;
  PricingConfig pricing = const PricingConfig(
    pricePerHour: kDefaultPricePerHour,
    depositAmount: kDefaultDepositAmount,
    minimumRequiredBalance: kDefaultMinimumRequiredBalance,
    lowBatteryThreshold: kDefaultLowBatteryThreshold,
  );

  /* --- public getters ------------------------------------------ */
  /* Countdown shown to the user. Before overdue: time left in the
   * pre-paid window. After overdue: time left in the current 1-hour
   * loop (resets every hour). */
  int get liveRemainingSeconds {
    final int total = _totalConsumedSeconds();
    final int selected = _selectedRentalHours * 3600;
    if (total < selected) {
      return (selected - total).clamp(
        0,
        FeatureConfig.rentalRemainingSecondsMax,
      );
    }
    final int overdue = total - selected;
    return 3600 - (overdue % 3600);
  }

  /* Total seconds the rental has gone past the originally-selected
   * window. 0 while still within the pre-paid hours. */
  int get overdueSeconds {
    final int total = _totalConsumedSeconds();
    final int selected = _selectedRentalHours * 3600;
    return total > selected ? total - selected : 0;
  }

  bool get isOverdue => overdueSeconds > 0;

  int get selectedRentalHours => _selectedRentalHours;
  int get selectedUsageFee => pricing.pricePerHour * _selectedRentalHours;
  int get selectedTotalRequired => selectedUsageFee + pricing.depositAmount;
  String? get currentBikeId => _bikeId;
  bool get isRunning => phase == RentalPhase.running;
  bool get isPaused => phase == RentalPhase.paused;
  bool get isEnded => phase == RentalPhase.ended;
  bool get hasActiveSession =>
      phase == RentalPhase.running || phase == RentalPhase.paused;
  int get effectivePricePerHour => isPaused
      ? (pricing.pricePerHour * FeatureConfig.rentalPausePriceFactorPercent) ~/
            100
      : pricing.pricePerHour;

  /* --- public methods ------------------------------------------ */
  void bindUser(MobileUserProfile? user) {
    final String? uid = user?.uid;
    final String? wireUserId = user == null
        ? null
        : buildWireUserId(uid: user.uid, phone: user.phone, email: user.email);
    if (_uid == uid && _wireUserId == wireUserId) return;
    _uid = uid;
    _wireUserId = wireUserId;
    _resetAll();
    notifyListeners();
  }

  void setSelectedRentalHours(int hours) {
    if (hours < 1) return;
    if (_selectedRentalHours == hours) return;
    _selectedRentalHours = hours;
    notifyListeners();
  }

  Future<bool> startRental({required String bikeId, int? rentalHours}) async {
    if (rentalHours != null) {
      setSelectedRentalHours(rentalHours);
    }
    if (_uid == null || _wireUserId == null) {
      lastError = 'Not signed in.';
      if (FeatureConfig.debugRideLog) {
        debugPrint('[Ride] startRental blocked: user not logged in');
      }
      notifyListeners();
      return false;
    }
    final String wireUserId = _wireUserId!;
    if (FeatureConfig.debugRideLog) {
      debugPrint(
        '[Ride] startRental requested: uid=$_uid wireUserId=$wireUserId bikeId=$bikeId',
      );
    }
    _bikeId = bikeId;
    _subscribeWebApp(bikeId);
    _telemetry?.watch(bikeId);

    phase = RentalPhase.starting;
    lastError = null;
    lastBill = null;
    notifyListeners();

    final bool ok = _mqtt.publish(
      MqttTopics.appToWeb(bikeId),
      ProtocolCodec.build(kCmdStartRental, [wireUserId]),
    );
    if (!ok) {
      if (FeatureConfig.debugRideLog) {
        debugPrint(
          '[Ride] startRental publish failed: uid=$_uid bikeId=$bikeId mqttConnected=${_mqtt.isConnected}',
        );
      }
      phase = RentalPhase.idle;
      lastError = 'Could not publish MQTT command. Check the connection.';
      notifyListeners();
    } else if (FeatureConfig.debugRideLog) {
      debugPrint('[Ride] startRental published: uid=$_uid bikeId=$bikeId');
    }
    return ok;
  }

  Future<void> pauseRide() async {
    if (_bikeId == null || _uid == null || _wireUserId == null) return;
    if (phase != RentalPhase.running) return;
    _mqtt.publish(
      MqttTopics.appToWeb(_bikeId!),
      ProtocolCodec.build(kCmdPause, [_wireUserId!]),
    );
  }

  Future<void> resumeRide() async {
    if (_bikeId == null || _uid == null || _wireUserId == null) return;
    if (phase != RentalPhase.paused) return;
    _mqtt.publish(
      MqttTopics.appToWeb(_bikeId!),
      ProtocolCodec.build(kCmdResume, [_wireUserId!]),
    );
  }

  Future<void> endRide() async {
    if (_bikeId == null || _uid == null || _wireUserId == null) return;
    if (!hasActiveSession) return;
    phase = RentalPhase.stopping;
    notifyListeners();
    _mqtt.publish(
      MqttTopics.appToWeb(_bikeId!),
      ProtocolCodec.build(kCmdStopRental, [_wireUserId!]),
    );
  }

  void clearWarning() {
    warning = null;
    notifyListeners();
  }

  void clearError() {
    lastError = null;
    notifyListeners();
  }

  void acknowledgeBill() {
    lastBill = null;
    phase = RentalPhase.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _webAppSub?.cancel();
    _timer?.cancel();
    _pauseTimeoutTimer?.cancel();
    super.dispose();
  }

  /* --- private methods ----------------------------------------- */
  void _resetAll() {
    _webAppSub?.cancel();
    _webAppSub = null;
    _timer?.cancel();
    _pauseTimeoutTimer?.cancel();
    final String? prevBike = _bikeId;
    if (prevBike != null) {
      _telemetry?.stopWatching(prevBike);
    }
    _bikeId = null;
    _startedAt = null;
    _consumedAtPhaseStart = 0;
    phase = RentalPhase.idle;
    lastBill = null;
    lastError = null;
    warning = null;
  }

  void _subscribeWebApp(String bikeId) {
    _webAppSub?.cancel();
    if (FeatureConfig.debugRideLog) {
      debugPrint(
        '[Ride] subscribe web->app topic: ${MqttTopics.webToApp(bikeId)}',
      );
    }
    _webAppSub = _mqtt
        .streamOf(MqttTopics.webToApp(bikeId))
        .listen(_handleWebAppMessage);
  }

  void _handleWebAppMessage(ProtocolMessage msg) {
    if (FeatureConfig.debugRideLog) {
      debugPrint(
        '[Ride] incoming web->app command=${msg.command} args=${msg.args}',
      );
    }
    switch (msg.command) {
      case kEvtStartRentalSuccess:
        _onStartSuccess(msg);
        break;
      case kEvtPauseSuccess:
        _onPauseSuccess();
        break;
      case kEvtResumeSuccess:
        _onResumeSuccess();
        break;
      case kEvtStopRentalFail:
        _onStopFail();
        break;
      case kEvtEndRental:
        _onEndRental(msg);
        break;
      case kEvtRentalErr:
        _onRentalErr(msg);
        break;
      case kEvtWarnLowBalance:
        warning = kEvtWarnLowBalance;
        notifyListeners();
        break;
      case kEvtWarnOutOfBalance:
        warning = kEvtWarnOutOfBalance;
        notifyListeners();
        break;
      case kEvtWarnDebt:
        /* WARN_DEBT=<total_debt_tokens> */
        warning = kEvtWarnDebt;
        debtAmount = int.tryParse(msg.argAt(0) ?? '') ?? debtAmount;
        notifyListeners();
        break;
      case kEvtRentalNotiLimit:
        /* RENTAL_NOTI_LIMIT[=<total_debt_tokens>] — account locked. */
        warning = kEvtRentalNotiLimit;
        debtAmount = int.tryParse(msg.argAt(0) ?? '') ?? debtAmount;
        notifyListeners();
        break;
      case kEvtDebtClear:
        /* DEBT_CLEAR — debt fully repaid mid-rental, dismiss debt UI. */
        if (warning == kEvtWarnDebt || warning == kEvtRentalNotiLimit) {
          warning = null;
        }
        debtAmount = 0;
        notifyListeners();
        break;
    }
  }

  void _onStartSuccess(ProtocolMessage msg) {
    /* START_RENTAL_SUCCESS=<user_id>,<start_time> */
    final String? startTimeStr = msg.argAt(1);
    _startedAt = startTimeStr != null ? DateTime.tryParse(startTimeStr) : null;
    _startedAt ??= DateTime.now();
    phase = RentalPhase.running;
    _consumedAtPhaseStart = 0;
    _restartTicker();
    notifyListeners();
  }

  void _onPauseSuccess() {
    /* Snapshot the running total BEFORE flipping phase, so the new
     * phase's elapsed accumulates against an accurate baseline. */
    _consumedAtPhaseStart = _totalConsumedSeconds();
    phase = RentalPhase.paused;
    _startedAt = DateTime.now();
    _restartTicker();
    _startPauseTimeout();
    notifyListeners();
  }

  void _onResumeSuccess() {
    _consumedAtPhaseStart = _totalConsumedSeconds();
    phase = RentalPhase.running;
    _startedAt = DateTime.now();
    _pauseTimeoutTimer?.cancel();
    _pauseTimeoutTimer = null;
    _restartTicker();
    notifyListeners();
  }

  void _onStopFail() {
    /* Vehicle is outside a valid parking zone — the ride continues.
     * Show guidance instead of dropping the active session. */
    warning = kErrOutOfParkingZone;
    phase = hasActiveSession ? phase : RentalPhase.running;
    if (phase == RentalPhase.stopping) phase = RentalPhase.running;
    notifyListeners();
  }

  void _onEndRental(ProtocolMessage msg) {
    /* END_RENTAL=<user_id>,<bill_amount>,<status> */
    final int amount = int.tryParse(msg.argAt(1) ?? '') ?? 0;
    final String status = _normalizeEndStatus(msg.argAt(2));
    lastBill = RentalBill(
      userId: msg.argAt(0) ?? _uid ?? '',
      amount: amount,
      status: status,
      endedAt: DateTime.now(),
    );
    phase = RentalPhase.ended;
    _timer?.cancel();
    _pauseTimeoutTimer?.cancel();
    notifyListeners();
  }

  void _onRentalErr(ProtocolMessage msg) {
    lastError = msg.argAt(0) ?? kErrUnknown;
    phase = RentalPhase.idle;
    notifyListeners();
  }

  void _restartTicker() {
    _timer?.cancel();
    if (_startedAt == null) return;
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_startedAt == null) return;
    /* The countdown / overdue values are computed lazily from
     * `_totalConsumedSeconds()` — the tick just nudges UI rebuilds. */
    notifyListeners();
  }

  int _totalConsumedSeconds() {
    final DateTime? started = _startedAt;
    if (started == null) return _consumedAtPhaseStart;
    final int elapsedReal = DateTime.now().difference(started).inSeconds;
    final int factor = phase == RentalPhase.paused
        ? FeatureConfig.rentalPausePriceFactorPercent
        : 100;
    return _consumedAtPhaseStart + (elapsedReal * factor) ~/ 100;
  }

  void _startPauseTimeout() {
    _pauseTimeoutTimer?.cancel();
    _pauseTimeoutTimer = Timer(
      const Duration(seconds: FeatureConfig.rentalPauseTimeoutSeconds),
      () {
        /* Local safety net — backend will send END_RENTAL. */
        if (phase == RentalPhase.paused) {
          lastError = kErrTimeLimitExceeded;
          notifyListeners();
        }
      },
    );
  }

  String _normalizeEndStatus(String? rawStatus) {
    final String normalized = (rawStatus ?? kStatusOk).trim();
    if (normalized.isEmpty) return kStatusOk;
    if (normalized.startsWith('status=')) {
      return normalized.substring('status='.length).trim();
    }
    return normalized;
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
