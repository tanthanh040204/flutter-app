/*
 * @file       mobile_ride_provider.dart
 * @brief      Orchestrates rental workflows over MQTT (START / PAUSE / RESUME /
 *             STOP / END / warnings) and exposes UI-friendly state.
 */

/* Imports ------------------------------------------------------------ */
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/mqtt_config.dart';
import '../models/error_codes.dart';
import '../models/mobile_user_profile.dart';
import '../models/pricing_config.dart';
import '../models/rental_bill.dart';
import '../services/mqtt_service.dart';
import '../services/protocol_codec.dart';
import '../services/user_wire_id.dart';

/* Constants ---------------------------------------------------------- */
const int kDefaultPricePerHour           = 10000;
const int kDefaultDepositAmount          = 10000;
const int kDefaultMinimumRequiredBalance = 20000;
const int kDefaultLowBatteryThreshold    = 20;
const int kRemainingSecondsMax           = 999999;
const int kPausePriceFactorPercent       = 50;
const int kPauseTimeoutSeconds           = 3600;

/* Enums -------------------------------------------------------------- */

enum RentalPhase {
  idle,        /* no active rental                                   */
  starting,    /* START_RENTAL sent, waiting for SUCCESS or ERR      */
  running,     /* session is active                                  */
  paused,      /* session is paused                                  */
  stopping,    /* STOP_RENTAL sent, waiting for END or FAIL          */
  ended,       /* received END_RENTAL — bill is available            */
}

/* Typedef / Function types ------------------------------------------ */
/* Public classes ----------------------------------------------------- */

class MobileRideProvider extends ChangeNotifier {
  MobileRideProvider(this._mqtt);

  /* --- private fields ------------------------------------------ */
  final MqttService               _mqtt;
  StreamSubscription<ProtocolMessage>? _webAppSub;
  Timer?                          _timer;
  Timer?                          _pauseTimeoutTimer;
  String?                         _uid;
  String?                         _wireUserId;
  String?                         _bikeId;
  DateTime?                       _startedAt;
  int                             _liveRemainingSeconds = 0;

  /* --- public fields ------------------------------------------- */
  RentalPhase phase = RentalPhase.idle;
  RentalBill? lastBill;
  String?     lastError;
  String?     warning;  /* WARN_LOW_BALANCE / WARN_OUT_OF_BALANCE  */
  PricingConfig pricing = const PricingConfig(
    pricePerHour:           kDefaultPricePerHour,
    depositAmount:          kDefaultDepositAmount,
    minimumRequiredBalance: kDefaultMinimumRequiredBalance,
    lowBatteryThreshold:    kDefaultLowBatteryThreshold,
  );

  /* --- public getters ------------------------------------------ */
  int     get liveRemainingSeconds => _liveRemainingSeconds;
  String? get currentBikeId        => _bikeId;
  bool    get isRunning            => phase == RentalPhase.running;
  bool    get isPaused             => phase == RentalPhase.paused;
  bool    get isEnded              => phase == RentalPhase.ended;
  bool    get hasActiveSession     =>
      phase == RentalPhase.running || phase == RentalPhase.paused;
  int     get effectivePricePerHour =>
      isPaused ? (pricing.pricePerHour * kPausePriceFactorPercent) ~/ 100
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

  Future<bool> startRental({required String bikeId}) async {
    if (_uid == null || _wireUserId == null) {
      lastError = 'Chưa đăng nhập.';
      debugPrint('[Ride] startRental blocked: user not logged in');
      notifyListeners();
      return false;
    }
    final String wireUserId = _wireUserId!;
    debugPrint(
      '[Ride] startRental requested: uid=$_uid wireUserId=$wireUserId bikeId=$bikeId',
    );
    _bikeId = bikeId;
    _subscribeWebApp(bikeId);

    phase     = RentalPhase.starting;
    lastError = null;
    lastBill  = null;
    notifyListeners();

    final bool ok = _mqtt.publish(
      MqttTopics.appToWeb(bikeId),
      ProtocolCodec.build(kCmdStartRental, [wireUserId]),
    );
    if (!ok) {
      debugPrint(
        '[Ride] startRental publish failed: uid=$_uid bikeId=$bikeId mqttConnected=${_mqtt.isConnected}',
      );
      phase     = RentalPhase.idle;
      lastError = 'Không gửi được lệnh MQTT. Kiểm tra kết nối.';
      notifyListeners();
    } else {
      debugPrint('[Ride] startRental published: uid=$_uid bikeId=$bikeId');
    }
    return ok;
  }

  Future<void> pauseRide() async {
    if (_bikeId == null || _uid == null || _wireUserId == null) return;
    if (phase   != RentalPhase.running)        return;
    _mqtt.publish(
      MqttTopics.appToWeb(_bikeId!),
      ProtocolCodec.build(kCmdPause, [_wireUserId!]),
    );
  }

  Future<void> resumeRide() async {
    if (_bikeId == null || _uid == null || _wireUserId == null) return;
    if (phase   != RentalPhase.paused)         return;
    _mqtt.publish(
      MqttTopics.appToWeb(_bikeId!),
      ProtocolCodec.build(kCmdResume, [_wireUserId!]),
    );
  }

  Future<void> endRide() async {
    if (_bikeId == null || _uid == null || _wireUserId == null) return;
    if (!hasActiveSession)                      return;
    phase = RentalPhase.stopping;
    notifyListeners();
    _mqtt.publish(
      MqttTopics.appToWeb(_bikeId!),
      ProtocolCodec.build(kCmdStopRental, [_wireUserId!]),
    );
  }

  void clearWarning()    { warning   = null; notifyListeners(); }
  void clearError()      { lastError = null; notifyListeners(); }
  void acknowledgeBill() { lastBill  = null; phase = RentalPhase.idle; notifyListeners(); }

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
    _bikeId                = null;
    _startedAt             = null;
    _liveRemainingSeconds  = 0;
    phase                  = RentalPhase.idle;
    lastBill               = null;
    lastError              = null;
    warning                = null;
  }

  void _subscribeWebApp(String bikeId) {
    _webAppSub?.cancel();
    debugPrint('[Ride] subscribe web->app topic: ${MqttTopics.webToApp(bikeId)}');
    _webAppSub = _mqtt
        .streamOf(MqttTopics.webToApp(bikeId))
        .listen(_handleWebAppMessage);
  }

  void _handleWebAppMessage(ProtocolMessage msg) {
    debugPrint('[Ride] incoming web->app command=${msg.command} args=${msg.args}');
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
    }
  }

  void _onStartSuccess(ProtocolMessage msg) {
    /* START_RENTAL_SUCCESS=<user_id>,<start_time> */
    final String? startTimeStr = msg.argAt(1);
    _startedAt =
        startTimeStr != null ? DateTime.tryParse(startTimeStr) : null;
    _startedAt ??= DateTime.now();
    phase       = RentalPhase.running;
    _liveRemainingSeconds = 0;
    _restartTicker();
    notifyListeners();
  }

  void _onPauseSuccess() {
    phase = RentalPhase.paused;
    _timer?.cancel();
    _startPauseTimeout();
    notifyListeners();
  }

  void _onResumeSuccess() {
    phase = RentalPhase.running;
    _pauseTimeoutTimer?.cancel();
    _pauseTimeoutTimer = null;
    _restartTicker();
    notifyListeners();
  }

  void _onStopFail() {
    /* Xe ngoài bãi — vẫn đang thuê. Hiển thị hướng dẫn. */
    warning = kErrOutOfParkingZone;
    phase   = hasActiveSession ? phase : RentalPhase.running;
    if (phase == RentalPhase.stopping) phase = RentalPhase.running;
    notifyListeners();
  }

  void _onEndRental(ProtocolMessage msg) {
    /* END_RENTAL=<user_id>,<bill_amount>,<status> */
    final int    amount = int.tryParse(msg.argAt(1) ?? '') ?? 0;
    final String status = _normalizeEndStatus(msg.argAt(2));
    lastBill = RentalBill(
      userId:  msg.argAt(0) ?? _uid ?? '',
      amount:  amount,
      status:  status,
      endedAt: DateTime.now(),
    );
    phase = RentalPhase.ended;
    _timer?.cancel();
    _pauseTimeoutTimer?.cancel();
    notifyListeners();
  }

  void _onRentalErr(ProtocolMessage msg) {
    lastError = msg.argAt(0) ?? kErrUnknown;
    phase     = RentalPhase.idle;
    notifyListeners();
  }

  void _restartTicker() {
    _timer?.cancel();
    if (_startedAt == null) return;
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final DateTime? started = _startedAt;
    if (started == null) return;
    final int elapsed = DateTime.now().difference(started).inSeconds;
    _liveRemainingSeconds = elapsed.clamp(0, kRemainingSecondsMax);
    notifyListeners();
  }

  void _startPauseTimeout() {
    _pauseTimeoutTimer?.cancel();
    _pauseTimeoutTimer = Timer(
      const Duration(seconds: kPauseTimeoutSeconds),
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
