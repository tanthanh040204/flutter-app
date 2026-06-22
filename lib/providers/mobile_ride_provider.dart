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
import '../models/device_telemetry.dart';
import '../models/error_codes.dart';
import '../models/mobile_user_profile.dart';
import '../models/pricing_config.dart';
import '../models/rental_bill.dart';
import '../models/ride_snapshot.dart';
import '../services/foreground_service.dart';
import '../services/mobile_user_repo.dart';
import '../services/mqtt_service.dart';
import '../services/protocol_codec.dart';
import '../services/user_wire_id.dart';
import 'mobile_notice_provider.dart';
import 'mobile_telemetry_provider.dart';

/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */

enum RentalPhase { idle, starting, running, paused, stopping, ended }

/* Typedef / Function types ------------------------------------------ */
/* Public classes ----------------------------------------------------- */

class MobileRideProvider extends ChangeNotifier {
  MobileRideProvider(
    this._mqtt,
    this._repo, {
    MobileTelemetryProvider? telemetry,
  }) : _telemetry = telemetry {
    _mqtt.addListener(_onMqttChanged);
  }

  /* --- private fields ------------------------------------------ */
  final MqttService _mqtt;
  final MobileUserRepo _repo;
  final MobileTelemetryProvider? _telemetry;
  MobileNoticeProvider? _notice;
  StreamSubscription<ProtocolMessage>? _webAppSub;
  StreamSubscription<ProtocolMessage>? _notiSub;
  Timer? _timer;
  Timer? _pauseTimeoutTimer;
  String? _uid;
  String? _wireUserId;
  String? _bikeId;
  DateTime? _startedAt;
  // Total bill = (initial hours + extra hours) * pricePerHour
  int _consumedAtPhaseStart = 0;
  int _selectedRentalHours = 1;
  bool _needStatusConfirm = false;
  int _authBlocks = 0;
  int _billedAmount = 0;

  /* --- public fields ------------------------------------------- */
  RentalPhase phase = RentalPhase.idle;
  RentalBill? lastBill;
  String? lastError;
  String?
  warning; /* WARN_LOW_BALANCE / WARN_OUT_OF_BALANCE / WARN_DEBT / RENTAL_NOTI_LIMIT */
  int debtAmount = 0;
  /* Danger-alert switch state mirrored on the device via cmd topic. */
  bool dangerNotiEnabled = true;
  PricingConfig pricing = const PricingConfig(
    pricePerHour: FeatureConfig.rentalDefaultPricePerHour,
    depositAmount: FeatureConfig.rentalDefaultDepositAmount,
    minimumRequiredBalance: FeatureConfig.rentalDefaultMinimumRequiredBalance,
    lowBatteryThreshold: FeatureConfig.rentalDefaultLowBatteryThreshold,
  );

  /* --- public getters ------------------------------------------ */
  /* Countdown shown to the user. Before overdue: time left in the
   * pre-paid window. After overdue: time left in the current billing
   * block (resets every block). */
  int get liveRemainingSeconds {
    final int total = _totalConsumedSeconds();
    final int block = FeatureConfig.rentalBillingBlockSeconds;
    final int selected = _selectedRentalHours * block;
    if (total < selected) {
      return (selected - total).clamp(
        0,
        FeatureConfig.rentalRemainingSecondsMax,
      );
    }
    final int overdue = total - selected;
    return block - (overdue % block);
  }

  /* The latest telemetry for the current bike, if any. */
  DeviceTelemetry? get latestTelemetry =>
      _bikeId != null ? _telemetry?.telemetryFor(_bikeId!) : null;

  /* Total seconds the rental has gone past the originally-selected
   * window. 0 while still within the pre-paid blocks. */
  int get overdueSeconds {
    final int total = _totalConsumedSeconds();
    final int selected =
        _selectedRentalHours * FeatureConfig.rentalBillingBlockSeconds;
    return total > selected ? total - selected : 0;
  }

  bool get isOverdue => overdueSeconds > 0;

  int get blocksConsumed => _authBlocks;
  int get billedAmount => _billedAmount;

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
  void attachNotice(MobileNoticeProvider notice) => _notice = notice;

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
    if (wireUserId != null) {
      unawaited(_restoreSession(wireUserId));
    }
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
    _subscribeDeviceNoti(bikeId);
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

  /* Toggle the device's danger-alert buzzer/notification via the cmd topic. */
  void setDangerNoti(bool enabled) {
    if (_bikeId == null) return;
    dangerNotiEnabled = enabled;
    _mqtt.publish(
      MqttTopics.deviceCmd(_bikeId!),
      ProtocolCodec.build(kCmdSetDangerNoti, [enabled ? '1' : '0']),
    );
    notifyListeners();
  }

  /* Ask the device to signal its location (find-my-bike). */
  void findVehicle() {
    if (_bikeId == null) return;
    _mqtt.publish(
      MqttTopics.deviceCmd(_bikeId!),
      ProtocolCodec.build(kCmdWhere),
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

  void clearDebt() {
    final bool hadDebt =
        debtAmount != 0 ||
        warning == kEvtWarnDebt ||
        warning == kEvtRentalNotiLimit;
    if (!hadDebt) return;
    if (warning == kEvtWarnDebt || warning == kEvtRentalNotiLimit) {
      warning = null;
    }
    debtAmount = 0;
    notifyListeners();
  }

  void acknowledgeBill() {
    lastBill = null;
    phase = RentalPhase.idle;
    notifyListeners();
  }

  /* Apply the user's outstanding debt fetched from the web at login, so the
   * home UI (which reads debtAmount) reflects it before any ride starts. */
  void setExternalDebt(int debt) {
    if (debtAmount == debt) return;
    debtAmount = debt;
    notifyListeners();
  }

  @override
  void dispose() {
    _mqtt.removeListener(_onMqttChanged);
    _webAppSub?.cancel();
    _notiSub?.cancel();
    _timer?.cancel();
    _pauseTimeoutTimer?.cancel();
    super.dispose();
  }

  /* --- private methods ----------------------------------------- */
  void _resetAll() {
    _webAppSub?.cancel();
    _webAppSub = null;
    _notiSub?.cancel();
    _notiSub = null;
    _timer?.cancel();
    _pauseTimeoutTimer?.cancel();
    final String? prevBike = _bikeId;
    if (prevBike != null) {
      _telemetry?.stopWatching(prevBike);
    }
    _bikeId = null;
    _startedAt = null;
    _consumedAtPhaseStart = 0;
    _authBlocks = 0;
    _billedAmount = 0;
    _needStatusConfirm = false;
    phase = RentalPhase.idle;
    lastBill = null;
    lastError = null;
    warning = null;
    dangerNotiEnabled = true;
    _stopForeground();
  }

  /* Reattach to an in-flight rental persisted before the app was killed. */
  Future<void> _restoreSession(String wireUserId) async {
    final RideSnapshot? snap = await _repo.fetchRideSnapshot(wireUserId);
    if (snap == null) return;
    /* The user may have changed, or started a fresh rental, while the
     * Firestore read was in flight. */
    if (_wireUserId != wireUserId || phase != RentalPhase.idle) return;

    _bikeId = snap.bikeId;
    _selectedRentalHours = snap.selectedRentalHours;
    _startedAt = snap.phaseStartedAt;
    _consumedAtPhaseStart = snap.consumedAtPhaseStart;
    phase = snap.status == kStatusPaused
        ? RentalPhase.paused
        : RentalPhase.running;

    _subscribeWebApp(snap.bikeId);
    _subscribeDeviceNoti(snap.bikeId);
    _telemetry?.watch(snap.bikeId);
    _restartTicker();
    if (phase == RentalPhase.paused) _startPauseTimeout();
    _startForeground();

    if (FeatureConfig.debugRideLog) {
      debugPrint(
        '[Ride] restored session bike=${snap.bikeId} phase=$phase '
        'hours=$_selectedRentalHours consumed=$_consumedAtPhaseStart',
      );
    }
    notifyListeners();

    _queryRentalStatus(snap.bikeId, wireUserId);
  }

  void _queryRentalStatus(String bikeId, String wireUserId) {
    final bool ok = _mqtt.publish(
      MqttTopics.appToWeb(bikeId),
      ProtocolCodec.build(kCmdQueryStatus, [wireUserId]),
    );

    _needStatusConfirm = !ok;
    if (FeatureConfig.debugRideLog) {
      debugPrint('[Ride] QUERY_STATUS sent bike=$bikeId published=$ok');
    }
  }

  void _onMqttChanged() {
    if (!_needStatusConfirm || !_mqtt.isConnected) return;
    final String? bikeId = _bikeId;
    final String? wireUserId = _wireUserId;
    if (bikeId == null ||
        wireUserId == null ||
        (phase != RentalPhase.running && phase != RentalPhase.paused)) {
      _needStatusConfirm = false;
      return;
    }
    _queryRentalStatus(bikeId, wireUserId);
  }

  void _persistSnapshot() {
    final String? wireUserId = _wireUserId;
    final String? bikeId = _bikeId;
    if (wireUserId == null || bikeId == null) return;
    if (phase != RentalPhase.running && phase != RentalPhase.paused) return;
    unawaited(
      _repo.saveRideSnapshot(
        RideSnapshot(
          wireUserId: wireUserId,
          bikeId: bikeId,
          status: phase == RentalPhase.paused ? kStatusPaused : kStatusActive,
          selectedRentalHours: _selectedRentalHours,
          phaseStartedAt: _startedAt ?? DateTime.now(),
          consumedAtPhaseStart: _consumedAtPhaseStart,
        ),
      ),
    );
  }

  void _clearSnapshot() {
    final String? wireUserId = _wireUserId;
    if (wireUserId == null) return;
    unawaited(_repo.clearRideSnapshot(wireUserId));
  }

  /* Keep the process + MQTT alive in the background for the rental's
   * lifetime so warnings / END_RENTAL are still received. */
  void _startForeground() {
    unawaited(
      RideForegroundService.start(
        title: 'UTE-go rental in progress',
        text: 'Keeping your rental session active.',
      ),
    );
  }

  void _stopForeground() {
    unawaited(RideForegroundService.stop());
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

  void _subscribeDeviceNoti(String bikeId) {
    _notiSub?.cancel();
    if (FeatureConfig.debugRideLog) {
      debugPrint(
        '[Ride] subscribe noti topic: ${MqttTopics.deviceNoti(bikeId)}',
      );
    }
    _notiSub = _mqtt
        .streamOf(MqttTopics.deviceNoti(bikeId))
        .listen(_handleDeviceNoti);
  }

  void _handleDeviceNoti(ProtocolMessage msg) {
    if (msg.command == kNotiStolen) {
      warning = kNotiStolen;
      if (_bikeId != null) _notice?.pushStolenAlert(_bikeId!);
      notifyListeners();
    }
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
      case kEvtNoActiveRental:
        _onNoActiveRental(msg);
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
        clearDebt();
        break;
      case kEvtBlockTick:
        _onBlockTick(msg);
        break;
    }
  }

  void _onBlockTick(ProtocolMessage msg) {
    if (phase != RentalPhase.running && phase != RentalPhase.paused) return;
    _authBlocks = int.tryParse(msg.argAt(0) ?? '') ?? _authBlocks;
    _billedAmount = int.tryParse(msg.argAt(1) ?? '') ?? _billedAmount;
    final int elapsedBlocks = _authBlocks > 0 ? _authBlocks - 1 : 0;
    _consumedAtPhaseStart =
        elapsedBlocks * FeatureConfig.rentalBillingBlockSeconds;
    _startedAt = DateTime.now();
    _restartTicker();
    _persistSnapshot();
    notifyListeners();
  }

  void _onStartSuccess(ProtocolMessage msg) {
    /* START_RENTAL_SUCCESS=<user_id>,<start_time> */
    final String? startTimeStr = msg.argAt(1);
    _startedAt = startTimeStr != null ? DateTime.tryParse(startTimeStr) : null;
    _startedAt ??= DateTime.now();
    phase = RentalPhase.running;
    _consumedAtPhaseStart = 0;
    _authBlocks = 0;
    _billedAmount = 0;
    _restartTicker();
    _persistSnapshot();
    _startForeground();
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
    _persistSnapshot();
    notifyListeners();
  }

  void _onResumeSuccess() {
    _consumedAtPhaseStart = _totalConsumedSeconds();
    phase = RentalPhase.running;
    _startedAt = DateTime.now();
    _pauseTimeoutTimer?.cancel();
    _pauseTimeoutTimer = null;
    _restartTicker();
    _persistSnapshot();
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
    _clearSnapshot();
    _stopForeground();
    notifyListeners();
  }

  void _onNoActiveRental(ProtocolMessage msg) {
    if (msg.argAt(0) != _wireUserId) return;
    if (phase != RentalPhase.running && phase != RentalPhase.paused) return;
    if (FeatureConfig.debugRideLog) {
      debugPrint('[Ride] NO_ACTIVE_RENTAL — clearing stale restored session');
    }
    _clearSnapshot();
    _resetAll();
    notifyListeners();
  }

  void _onRentalErr(ProtocolMessage msg) {
    lastError = msg.argAt(0) ?? kErrUnknown;
    phase = RentalPhase.idle;
    _clearSnapshot();
    _stopForeground();
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
