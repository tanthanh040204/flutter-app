import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/pricing_config.dart';
import '../models/rental_vehicle.dart';
import '../models/user_ride_session.dart';
import '../services/mobile_user_repo.dart';

class MobileRideProvider extends ChangeNotifier {
  MobileRideProvider(this._repo) {
    _pricingSub = _repo.watchPricing().listen((event) {
      pricing = event;
      notifyListeners();
    });
  }

  final MobileUserRepo _repo;
  StreamSubscription<UserRideSession?>? _sessionSub;
  StreamSubscription<RentalVehicle?>? _vehicleSub;
  StreamSubscription<PricingConfig>? _pricingSub;
  Timer? _timer;

  String? _uid;
  UserRideSession? session;
  RentalVehicle? vehicle;

  PricingConfig pricing = const PricingConfig(
    pricePerHour: 10000,
    depositAmount: 10000,
    minimumRequiredBalance: 20000,
    lowBatteryThreshold: 20,
  );

  int _liveRemainingSeconds = 0;
  int get liveRemainingSeconds => _liveRemainingSeconds;

  // Người dùng tự nhập số giờ thuê
  int _selectedRentalHours = 1;
  int get selectedRentalHours => _selectedRentalHours;

  void setSelectedRentalHours(int hours) {
    if (hours < 1) return;
    if (_selectedRentalHours == hours) return;
    _selectedRentalHours = hours;
    notifyListeners();
  }

  int get selectedUsageFee => pricing.pricePerHour * _selectedRentalHours;

  int get selectedTotalRequired => selectedUsageFee + pricing.depositAmount;

  bool get showExtendPrompt =>
      session != null &&
      !session!.isEnded &&
      liveRemainingSeconds > 0 &&
      liveRemainingSeconds <= 15 * 60 &&
      (vehicle?.isLocked == false);

  bool get showReturnPrompt =>
      session != null &&
      !session!.isEnded &&
      liveRemainingSeconds == 0 &&
      (vehicle?.isLocked == false);

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
    final current = session;
    if (current == null) {
      _liveRemainingSeconds = 0;
      return;
    }
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final current = session;
    if (current == null) {
      _liveRemainingSeconds = 0;
      notifyListeners();
      return;
    }

    if (current.isPaused || current.isEnded || current.runningSince == null) {
      _liveRemainingSeconds = current.remainingSeconds.clamp(0, 999999).toInt();
      notifyListeners();
      return;
    }

    final elapsed = DateTime.now().difference(current.runningSince!).inSeconds;
    final remaining = (current.remainingSeconds - elapsed).clamp(0, 999999);
    _liveRemainingSeconds = remaining.toInt();
    notifyListeners();
  }

  Future<void> pauseRide() async {
    final current = session;
    if (current == null) return;
    await _repo.pauseRide(current);
  }

  Future<void> resumeRide() async {
    final current = session;
    if (current == null) return;
    await _repo.resumeRide(current);
  }

  Future<void> endRide() async {
    final current = session;
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
}
