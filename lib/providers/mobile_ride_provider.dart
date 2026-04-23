/*
 * @file       mobile_ride_provider.dart
 * @brief      Ride state: current session, vehicle telemetry and live ticker.
 */

/* Imports ------------------------------------------------------------ */
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/pricing_config.dart';
import '../models/rental_vehicle.dart';
import '../models/user_ride_session.dart';
import '../services/mobile_user_repo.dart';

/* Constants ---------------------------------------------------------- */
const int kDefaultPricePerHour = 10000;
const int kDefaultDepositAmount = 10000;
const int kDefaultMinimumRequiredBalance = 20000;
const int kDefaultLowBatteryThreshold = 20;
const int kRemainingSecondsMax = 999999;

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class MobileRideProvider extends ChangeNotifier {
  MobileRideProvider(this._repo) {
    _pricingSub = _repo.watchPricing().listen((event) {
      pricing = event;
      notifyListeners();
    });
  }

  /* --- private fields ------------------------------------------ */
  final MobileUserRepo _repo;
  StreamSubscription<UserRideSession?>? _sessionSub;
  StreamSubscription<RentalVehicle?>? _vehicleSub;
  StreamSubscription<PricingConfig>? _pricingSub;
  Timer? _timer;
  String? _uid;
  int _liveRemainingSeconds = 0;

  /* --- public fields ------------------------------------------- */
  UserRideSession? session;
  RentalVehicle? vehicle;
  PricingConfig pricing = const PricingConfig(
    pricePerHour: kDefaultPricePerHour,
    depositAmount: kDefaultDepositAmount,
    minimumRequiredBalance: kDefaultMinimumRequiredBalance,
    lowBatteryThreshold: kDefaultLowBatteryThreshold,
  );

  /* --- public getters ------------------------------------------ */
  int get liveRemainingSeconds => _liveRemainingSeconds;

  /* --- public methods ------------------------------------------ */
  void bindUser(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _sessionSub?.cancel();
    _vehicleSub?.cancel();
    session = null;
    vehicle = null;
    _timer?.cancel();
    _liveRemainingSeconds = 0;
    notifyListeners();

    if (uid == null) return;

    _sessionSub = _repo.watchCurrentSession(uid).listen((event) {
      session = event;
      _bindVehicle(event?.vehicleId);
      _restartTicker();
      notifyListeners();
    });
  }

  Future<void> pauseRide() async {
    final UserRideSession? current = session;
    if (current == null) return;
    await _repo.pauseRide(current);
  }

  Future<void> resumeRide() async {
    final UserRideSession? current = session;
    if (current == null) return;
    await _repo.resumeRide(current);
  }

  Future<void> endRide() async {
    final UserRideSession? current = session;
    if (current == null) return;
    await _repo.endRide(current);
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _vehicleSub?.cancel();
    _pricingSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  /* --- private methods ----------------------------------------- */
  void _bindVehicle(String? vehicleId) {
    _vehicleSub?.cancel();
    vehicle = null;
    if (vehicleId == null || vehicleId.isEmpty) return;
    _vehicleSub = _repo.watchVehicle(vehicleId).listen((event) {
      vehicle = event;
      notifyListeners();
    });
  }

  void _restartTicker() {
    _timer?.cancel();
    final UserRideSession? current = session;
    if (current == null) {
      _liveRemainingSeconds = 0;
      return;
    }
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final UserRideSession? current = session;
    if (current == null) {
      _liveRemainingSeconds = 0;
      notifyListeners();
      return;
    }
    if (current.isPaused || current.isEnded) {
      _liveRemainingSeconds = current.remainingSeconds;
      notifyListeners();
      return;
    }
    final int elapsed = DateTime.now().difference(current.startedAt).inSeconds;
    final int remaining = (current.remainingSeconds - elapsed).clamp(
      0,
      kRemainingSecondsMax,
    );
    _liveRemainingSeconds = remaining;
    notifyListeners();
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
