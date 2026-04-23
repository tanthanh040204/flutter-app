/*
 * @file       mobile_user_repo.dart
 * @brief      Single repository facade for authentication, wallet, ride
 *             sessions and demo fallbacks when Firebase is not configured.
 */

/* Imports ------------------------------------------------------------ */
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:latlong2/latlong.dart';

import '../models/mobile_history_route.dart';
import '../models/mobile_user_profile.dart';
import '../models/pricing_config.dart';
import '../models/rental_vehicle.dart';
import '../models/station.dart';
import '../models/user_notice.dart';
import '../models/user_ride_session.dart';

/* Constants ---------------------------------------------------------- */
/* --- Firestore collection names ---------------------------------- */
const String kColUsers = 'users';
const String kColStations = 'stations';
const String kColRideSessions = 'ride_sessions';
const String kColVehicles = 'vehicles';
const String kColNotifications = 'notifications';
const String kColVehicleCommands = 'vehicle_commands';
const String kColWalletTopups = 'wallet_topups';
const String kColWalletTxs = 'wallet_transactions';
const String kColLoginEvents = 'login_events';
const String kColAppConfigs = 'app_configs';
const String kDocPricing = 'pricing';

/* --- Pricing defaults ------------------------------------------- */
const int kDefaultPricePerHour = 10000;
const int kDefaultDepositAmount = 10000;
const int kDefaultMinimumRequiredBalance = 20000;
const int kDefaultLowBatteryThreshold = 20;
const int kInitialRemainingSeconds = 3600;

/* --- Balance defaults ------------------------------------------- */
const int kDemoSeedBalance = 120000;
const int kNewUserSeedBalance = 30000;

/* --- Status strings --------------------------------------------- */
const String kStatusPending = 'pending';
const String kStatusActive = 'active';
const String kStatusPaused = 'paused';
const String kStatusEnded = 'ended';

/* --- Project / demo -------------------------------------------- */
const String kDemoProjectId = 'demo-project';
const String kNoticeQueryLimit = '50';

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class MobileUserRepo {
  MobileUserRepo._();

  static final MobileUserRepo instance = MobileUserRepo._();

  /* --- private fields ------------------------------------------ */
  final Random _rnd = Random();
  final Map<String, _DemoAccount> _demoAccounts = {
    'demo@tngo.vn': _DemoAccount(
      uid: '1234567890',
      email: 'demo@tngo.vn',
      phone: '0900000001',
      password: '123456',
      employeeCode: 'NV001',
      fullName: 'Nguyễn Cao Tấn Thành',
      balance: kDemoSeedBalance,
    ),
    '0900000001': _DemoAccount(
      uid: '1234567890',
      email: 'demo@tngo.vn',
      phone: '0900000001',
      password: '123456',
      employeeCode: 'NV001',
      fullName: 'Nguyễn Cao Tấn Thành',
      balance: kDemoSeedBalance,
    ),
  };
  final Map<String, StreamController<MobileUserProfile>> _demoProfiles = {};
  final Map<String, StreamController<UserRideSession?>> _demoSessions = {};
  final Map<String, StreamController<RentalVehicle?>> _demoVehicles = {};
  final Map<String, StreamController<List<UserNotice>>> _demoNotices = {};
  final StreamController<List<BikeStation>> _demoStationsCtl =
      StreamController<List<BikeStation>>.broadcast();

  final Map<String, UserRideSession> _activeSessions = {};
  final Map<String, RentalVehicle> _vehicles = {
    'V1': RentalVehicle(
      id: 'V1',
      name: 'Xe 1',
      batteryPercent: 87,
      isLocked: true,
      isRunning: false,
      isPaused: false,
      isInUse: false,
      currentUserId: null,
      currentSessionId: null,
      totalKm: 162.5,
      temp: 30.2,
      hum: 78.1,
      dust: 16.0,
      lastLocation: const LatLng(10.7791, 106.6998),
      updatedAt: _bootTime,
    ),
  };

  /* Snapshot of construction time for initial vehicle timestamp (singleton). */
  static final DateTime _bootTime = DateTime.now();

  final PricingConfig _demoPricing = const PricingConfig(
    pricePerHour: kDefaultPricePerHour,
    depositAmount: kDefaultDepositAmount,
    minimumRequiredBalance: kDefaultMinimumRequiredBalance,
    lowBatteryThreshold: kDefaultLowBatteryThreshold,
  );

  /* --- private getters ----------------------------------------- */
  bool get _isReady => Firebase.apps.isNotEmpty;

  bool get _useLocalDemo {
    if (!_isReady) return true;
    try {
      return Firebase.app().options.projectId.trim().toLowerCase() ==
          kDemoProjectId;
    } catch (_) {
      return true;
    }
  }

  FirebaseFirestore? get _db =>
      _useLocalDemo ? null : FirebaseFirestore.instance;
  FirebaseAuth? get _auth => _useLocalDemo ? null : FirebaseAuth.instance;

  List<BikeStation> get _seedStations => const [
    BikeStation(
      id: 'ST_HCM_001',
      name: 'Công viên 30/4',
      city: 'TP.HCM',
      address: 'Lê Duẩn, Bến Nghé, Quận 1, TP.HCM',
      point: LatLng(10.7791, 106.6998),
      googleMapUrl:
          'https://www.google.com/maps/search/?api=1&query=10.7791,106.6998',
      bikeCount: 10,
      availableSlots: 6,
      isActive: true,
    ),
    BikeStation(
      id: 'ST_HCM_002',
      name: 'Công viên Tao Đàn',
      city: 'TP.HCM',
      address: 'Trương Định, Bến Thành, Quận 1, TP.HCM',
      point: LatLng(10.7769, 106.6918),
      googleMapUrl:
          'https://www.google.com/maps/search/?api=1&query=10.7769,106.6918',
      bikeCount: 13,
      availableSlots: 2,
      isActive: true,
    ),
    BikeStation(
      id: 'ST_HCM_003',
      name: 'Trống Đồng',
      city: 'TP.HCM',
      address: '12B CMT8, Bến Thành, Quận 1, TP.HCM',
      point: LatLng(10.7760, 106.6942),
      googleMapUrl:
          'https://www.google.com/maps/search/?api=1&query=10.7760,106.6942',
      bikeCount: 13,
      availableSlots: 6,
      isActive: true,
    ),
    BikeStation(
      id: 'ST_HN_001',
      name: 'Hồ Gươm',
      city: 'Hà Nội',
      address: 'Hoàn Kiếm, Hà Nội',
      point: LatLng(21.0287, 105.8522),
      googleMapUrl:
          'https://www.google.com/maps/search/?api=1&query=21.0287,105.8522',
      bikeCount: 9,
      availableSlots: 8,
      isActive: true,
    ),
    BikeStation(
      id: 'ST_HN_002',
      name: 'Nhà hát Lớn',
      city: 'Hà Nội',
      address: 'Tràng Tiền, Hoàn Kiếm, Hà Nội',
      point: LatLng(21.0245, 105.8570),
      googleMapUrl:
          'https://www.google.com/maps/search/?api=1&query=21.0245,105.8570',
      bikeCount: 7,
      availableSlots: 4,
      isActive: true,
    ),
  ];

  /* --- public methods (auth) ----------------------------------- */
  Future<MobileUserProfile> signIn({
    required String identifier,
    required String password,
    required bool usePhone,
  }) async {
    if (_useLocalDemo) {
      final _DemoAccount? account = _demoAccounts[identifier.trim()];
      if (account == null || account.password != password.trim()) {
        throw Exception('Thông tin đăng nhập không đúng.');
      }
      final MobileUserProfile profile = _demoProfileFromAccount(
        account,
      ).copyWith(lastLoginAt: DateTime.now());
      _pushDemoProfile(profile);
      await addLoginEvent(profile.employeeCode);
      return profile;
    }

    if (usePhone) {
      throw Exception(
        'Bản MVP hiện mới hỗ trợ email/password thật. Phone login đang để chế độ demo.',
      );
    }

    final UserCredential cred = await _auth!.signInWithEmailAndPassword(
      email: identifier.trim(),
      password: password.trim(),
    );

    final String uid = cred.user!.uid;
    final MobileUserProfile profile = await getOrCreateUserProfile(
      uid: uid,
      email: cred.user!.email,
      phone: cred.user!.phoneNumber,
      fullName: cred.user!.displayName ?? 'Người dùng mới',
    );

    await addLoginEvent(profile.employeeCode);
    return profile;
  }

  Future<MobileUserProfile> register({
    required String fullName,
    required String employeeCode,
    required String identifier,
    required String password,
    required bool usePhone,
  }) async {
    if (_useLocalDemo) {
      final String uid = 'demo_${DateTime.now().millisecondsSinceEpoch}';
      final _DemoAccount account = _DemoAccount(
        uid: uid,
        email: usePhone ? null : identifier.trim(),
        phone: usePhone ? identifier.trim() : null,
        password: password.trim(),
        employeeCode: employeeCode.trim(),
        fullName: fullName.trim(),
        balance: kNewUserSeedBalance,
      );
      _demoAccounts[identifier.trim()] = account;
      final MobileUserProfile profile = _demoProfileFromAccount(account);
      _pushDemoProfile(profile);
      await addLoginEvent(profile.employeeCode);
      return profile;
    }

    if (usePhone) {
      throw Exception(
        'Bản MVP hiện mới hỗ trợ email/password thật. Phone register đang để chế độ demo.',
      );
    }

    final UserCredential cred = await _auth!.createUserWithEmailAndPassword(
      email: identifier.trim(),
      password: password.trim(),
    );

    final String uid = cred.user!.uid;
    final MobileUserProfile profile = MobileUserProfile(
      uid: uid,
      employeeCode: employeeCode.trim(),
      fullName: fullName.trim(),
      phone: null,
      email: identifier.trim(),
      role: 'user',
      balance: kNewUserSeedBalance,
      depositLocked: 0,
      isActive: true,
      currentSessionId: null,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    await _saveUserProfile(profile);
    await addLoginEvent(profile.employeeCode);
    return profile;
  }

  Future<void> signOut() async {
    await _auth?.signOut();
  }

  Future<MobileUserProfile> getOrCreateUserProfile({
    required String uid,
    required String? email,
    required String? phone,
    required String fullName,
  }) async {
    final FirebaseFirestore? db = _db;
    if (db == null) {
      final _DemoAccount account = _demoAccounts.values.first;
      return _demoProfileFromAccount(account);
    }

    final DocumentReference<Map<String, dynamic>> ref = db
        .collection(kColUsers)
        .doc(uid);
    final DocumentSnapshot<Map<String, dynamic>> snap = await ref.get();
    if (snap.exists) {
      return _profileFromDoc(snap);
    }

    final MobileUserProfile profile = MobileUserProfile(
      uid: uid,
      employeeCode: 'NV${1000 + _rnd.nextInt(9000)}',
      fullName: fullName,
      phone: phone,
      email: email,
      role: 'user',
      balance: kNewUserSeedBalance,
      depositLocked: 0,
      isActive: true,
      currentSessionId: null,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    await _saveUserProfile(profile);
    return profile;
  }

  Future<void> changePassword({
    required String uid,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_db == null) {
      final _DemoAccount account = _demoAccounts.values.firstWhere(
        (e) => e.uid == uid,
      );
      if (account.password != currentPassword.trim()) {
        throw Exception('Mật khẩu hiện tại không đúng.');
      }
      _replaceDemoAccount(account.copyWith(password: newPassword.trim()));
      return;
    }
    final User? user = _auth!.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Không thể đổi mật khẩu ở tài khoản hiện tại.');
    }
    final AuthCredential cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword.trim(),
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword.trim());
  }

  /* --- public methods (streams) -------------------------------- */
  Stream<MobileUserProfile?> watchUserProfile(String uid) {
    final FirebaseFirestore? db = _db;
    if (db == null) {
      final StreamController<MobileUserProfile> ctl = _demoProfiles.putIfAbsent(
        uid,
        () => StreamController<MobileUserProfile>.broadcast(),
      );
      final _DemoAccount account = _demoAccounts.values.firstWhere(
        (e) => e.uid == uid,
        orElse: () => _demoAccounts.values.first,
      );
      Future.microtask(() => ctl.add(_demoProfileFromAccount(account)));
      return ctl.stream;
    }

    return db.collection(kColUsers).doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _profileFromDoc(doc);
    });
  }

  Stream<PricingConfig> watchPricing() {
    final FirebaseFirestore? db = _db;
    if (db == null) {
      return Stream.value(_demoPricing);
    }
    return db.collection(kColAppConfigs).doc(kDocPricing).snapshots().map((
      doc,
    ) {
      final Map<String, dynamic> m = doc.data() ?? {};
      return PricingConfig(
        pricePerHour: _asInt(m['pricePerHour'], kDefaultPricePerHour),
        depositAmount: _asInt(m['depositAmount'], kDefaultDepositAmount),
        minimumRequiredBalance: _asInt(
          m['minimumRequiredBalance'],
          kDefaultMinimumRequiredBalance,
        ),
        lowBatteryThreshold: _asInt(
          m['lowBatteryThreshold'],
          kDefaultLowBatteryThreshold,
        ),
      );
    });
  }

  Stream<List<BikeStation>> watchStations() {
    final FirebaseFirestore? db = _db;
    if (db == null) {
      Future.microtask(() => _demoStationsCtl.add(_seedStations));
      return _demoStationsCtl.stream;
    }
    return db
        .collection(kColStations)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => _stationFromDoc(doc)).toList());
  }

  Stream<UserRideSession?> watchCurrentSession(String uid) {
    final FirebaseFirestore? db = _db;
    if (db == null) {
      final StreamController<UserRideSession?> ctl = _demoSessions.putIfAbsent(
        uid,
        () => StreamController<UserRideSession?>.broadcast(),
      );
      Future.microtask(() => ctl.add(_activeSessions[uid]));
      return ctl.stream;
    }
    return db
        .collection(kColRideSessions)
        .where('uid', isEqualTo: uid)
        .where(
          'status',
          whereIn: [kStatusPending, kStatusActive, kStatusPaused],
        )
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          return _sessionFromDoc(snap.docs.first);
        });
  }

  Stream<RentalVehicle?> watchVehicle(String vehicleId) {
    final FirebaseFirestore? db = _db;
    if (db == null) {
      final StreamController<RentalVehicle?> ctl = _demoVehicles.putIfAbsent(
        vehicleId,
        () => StreamController<RentalVehicle?>.broadcast(),
      );
      Future.microtask(() => ctl.add(_vehicles[vehicleId]));
      return ctl.stream;
    }
    return db.collection(kColVehicles).doc(vehicleId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _vehicleFromDoc(doc);
    });
  }

  Stream<List<UserNotice>> watchUserNotifications(String uid) {
    final FirebaseFirestore? db = _db;
    if (db == null) {
      final StreamController<List<UserNotice>> ctl = _demoNotices.putIfAbsent(
        uid,
        () => StreamController<List<UserNotice>>.broadcast(),
      );
      Future.microtask(() => ctl.add(_seedNotices(uid)));
      return ctl.stream;
    }
    return db
        .collection(kColNotifications)
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(_noticeFromDoc).toList());
  }

  Stream<List<MobileHistoryRoute>> watchUserRoutes({
    required String vehicleId,
    int keepDays = 30,
  }) {
    final FirebaseFirestore? db = _db;
    if (db == null) {
      return Stream.value(_seedRoutes(vehicleId));
    }
    final DateTime keepFrom = DateTime.now().subtract(
      Duration(days: keepDays - 1),
    );
    return db
        .collection(kColVehicles)
        .doc(vehicleId)
        .collection('history_routes')
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(keepFrom))
        .orderBy('startAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_routeFromDoc).toList());
  }

  /* --- public methods (events) --------------------------------- */
  Future<void> addLoginEvent(String employeeCode) async {
    final FirebaseFirestore? db = _db;
    if (db == null) return;

    await db.collection(kColLoginEvents).add({
      'employeeCode': employeeCode,
      'source': 'mobile',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await db.collection(kColNotifications).add({
      'target': 'admin',
      'type': 'login_event',
      'title': 'Đăng nhập mới',
      'body': 'Mã số $employeeCode vừa đăng nhập',
      'uid': null,
      'vehicleId': null,
      'sessionId': null,
      'routeId': null,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createTopupRequest({
    required String uid,
    required int amount,
  }) async {
    final FirebaseFirestore? db = _db;
    final String transferContent = 'NAPTIEN_$uid';
    if (db == null) {
      final _DemoAccount account = _demoAccounts.values.firstWhere(
        (e) => e.uid == uid,
      );
      final _DemoAccount updated = account.copyWith(
        balance: account.balance + amount,
      );
      _replaceDemoAccount(updated);
      _pushDemoProfile(_demoProfileFromAccount(updated));
      return;
    }

    await db.collection(kColWalletTopups).add({
      'uid': uid,
      'amount': amount,
      'status': kStatusPending,
      'paymentMethod': 'bank_qr',
      'transferContent': transferContent,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /* --- public methods (ride lifecycle) ------------------------- */
  Future<void> startRide({
    required MobileUserProfile user,
    required RentalVehicle vehicle,
    required PricingConfig pricing,
  }) async {
    if (user.balance < pricing.minimumRequiredBalance) {
      throw Exception('Số dư chưa đủ 20.000 VND để bắt đầu chuyến đi.');
    }
    if (vehicle.isInUse) {
      throw Exception('Xe đang được người khác sử dụng.');
    }

    final DateTime now = DateTime.now();
    final String sessionId = 'RS_${now.millisecondsSinceEpoch}';

    if (_db == null) {
      final UserRideSession session = UserRideSession(
        sessionId: sessionId,
        uid: user.uid,
        employeeCode: user.employeeCode,
        userName: user.fullName,
        vehicleId: vehicle.id,
        vehicleName: vehicle.name,
        stationStartId: 'ST_HCM_001',
        stationEndId: null,
        status: kStatusActive,
        startedAt: now,
        pausedAt: null,
        endedAt: null,
        lastHeartbeatAt: now,
        pricePerHour: pricing.pricePerHour,
        depositAmount: pricing.depositAmount,
        mainAmountUsed: pricing.pricePerHour,
        depositUsed: 0,
        remainingBalanceSnapshot: user.balance - pricing.totalRequired,
        remainingSeconds: kInitialRemainingSeconds,
        canUnlock: true,
        routeIds: const [],
      );
      _activeSessions[user.uid] = session;
      _demoSessions[user.uid]?.add(session);

      final RentalVehicle updatedVehicle = RentalVehicle(
        id: vehicle.id,
        name: vehicle.name,
        batteryPercent: vehicle.batteryPercent,
        isLocked: false,
        isRunning: true,
        isPaused: false,
        isInUse: true,
        currentUserId: user.uid,
        currentSessionId: sessionId,
        totalKm: vehicle.totalKm,
        temp: vehicle.temp,
        hum: vehicle.hum,
        dust: vehicle.dust,
        lastLocation: vehicle.lastLocation,
        updatedAt: now,
      );
      _vehicles[vehicle.id] = updatedVehicle;
      _demoVehicles[vehicle.id]?.add(updatedVehicle);

      final _DemoAccount updatedAccount = _demoAccounts.values
          .firstWhere((e) => e.uid == user.uid)
          .copyWith(balance: user.balance - pricing.totalRequired);
      _replaceDemoAccount(updatedAccount);
      _pushDemoProfile(
        _demoProfileFromAccount(
          updatedAccount,
        ).copyWith(currentSessionId: sessionId),
      );
      return;
    }

    final WriteBatch batch = _db!.batch();
    final DocumentReference sessionRef = _db!
        .collection(kColRideSessions)
        .doc(sessionId);
    final DocumentReference vehicleRef = _db!
        .collection(kColVehicles)
        .doc(vehicle.id);
    final DocumentReference userRef = _db!.collection(kColUsers).doc(user.uid);
    final DocumentReference commandRef = _db!
        .collection(kColVehicleCommands)
        .doc();
    final DocumentReference noticeRef = _db!
        .collection(kColNotifications)
        .doc();
    final DocumentReference tx1 = _db!.collection(kColWalletTxs).doc();
    final DocumentReference tx2 = _db!.collection(kColWalletTxs).doc();

    batch.set(sessionRef, {
      'sessionId': sessionId,
      'uid': user.uid,
      'employeeCode': user.employeeCode,
      'userName': user.fullName,
      'vehicleId': vehicle.id,
      'vehicleName': vehicle.name,
      'stationStartId': null,
      'stationEndId': null,
      'status': kStatusActive,
      'startedAt': Timestamp.fromDate(now),
      'pausedAt': null,
      'endedAt': null,
      'lastHeartbeatAt': Timestamp.fromDate(now),
      'pricePerHour': pricing.pricePerHour,
      'depositAmount': pricing.depositAmount,
      'mainAmountUsed': pricing.pricePerHour,
      'depositUsed': 0,
      'remainingBalanceSnapshot': user.balance - pricing.totalRequired,
      'remainingSeconds': kInitialRemainingSeconds,
      'canUnlock': true,
      'routeIds': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(vehicleRef, {
      'isLocked': false,
      'isRunning': true,
      'isPaused': false,
      'isInUse': true,
      'currentUserId': user.uid,
      'currentSessionId': sessionId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(userRef, {
      'balance': user.balance - pricing.totalRequired,
      'depositLocked': pricing.depositAmount,
      'currentSessionId': sessionId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(commandRef, {
      'vehicleId': vehicle.id,
      'sessionId': sessionId,
      'uid': user.uid,
      'type': 'unlock',
      'status': kStatusPending,
      'source': 'mobile',
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(noticeRef, {
      'uid': user.uid,
      'target': 'user',
      'vehicleId': vehicle.id,
      'sessionId': sessionId,
      'type': 'ride_status',
      'title': '${vehicle.name} đang được sử dụng',
      'body': 'Bạn còn 60 phút sử dụng với số dư hiện tại.',
      'routeId': null,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(tx1, {
      'uid': user.uid,
      'type': 'rent_fee',
      'amount': pricing.pricePerHour,
      'balanceBefore': user.balance,
      'balanceAfter': user.balance - pricing.pricePerHour,
      'description': 'Thuê 1 giờ đầu cho ${vehicle.name}',
      'sessionId': sessionId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(tx2, {
      'uid': user.uid,
      'type': 'deposit_lock',
      'amount': pricing.depositAmount,
      'balanceBefore': user.balance - pricing.pricePerHour,
      'balanceAfter': user.balance - pricing.totalRequired,
      'description': 'Giữ cọc cho ${vehicle.name}',
      'sessionId': sessionId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> pauseRide(UserRideSession session) async {
    await _updateSessionStatus(session, kStatusPaused);
  }

  Future<void> resumeRide(UserRideSession session) async {
    await _updateSessionStatus(session, kStatusActive);
  }

  Future<void> endRide(UserRideSession session) async {
    final DateTime now = DateTime.now();
    if (_db == null) {
      _activeSessions.remove(session.uid);
      _demoSessions[session.uid]?.add(null);
      final RentalVehicle? vehicle = _vehicles[session.vehicleId];
      if (vehicle != null) {
        final RentalVehicle updated = RentalVehicle(
          id: vehicle.id,
          name: vehicle.name,
          batteryPercent: vehicle.batteryPercent,
          isLocked: true,
          isRunning: false,
          isPaused: false,
          isInUse: false,
          currentUserId: null,
          currentSessionId: null,
          totalKm: vehicle.totalKm,
          temp: vehicle.temp,
          hum: vehicle.hum,
          dust: vehicle.dust,
          lastLocation: vehicle.lastLocation,
          updatedAt: now,
        );
        _vehicles[vehicle.id] = updated;
        _demoVehicles[vehicle.id]?.add(updated);
      }
      final _DemoAccount account = _demoAccounts.values.firstWhere(
        (e) => e.uid == session.uid,
      );
      _pushDemoProfile(
        _demoProfileFromAccount(account).copyWith(currentSessionId: null),
      );
      return;
    }

    final WriteBatch batch = _db!.batch();
    final DocumentReference sessionRef = _db!
        .collection(kColRideSessions)
        .doc(session.sessionId);
    final DocumentReference vehicleRef = _db!
        .collection(kColVehicles)
        .doc(session.vehicleId);
    final DocumentReference userRef = _db!
        .collection(kColUsers)
        .doc(session.uid);
    final DocumentReference commandRef = _db!
        .collection(kColVehicleCommands)
        .doc();
    final DocumentReference noticeRef = _db!
        .collection(kColNotifications)
        .doc();

    batch.set(sessionRef, {
      'status': kStatusEnded,
      'endedAt': Timestamp.fromDate(now),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(vehicleRef, {
      'isLocked': true,
      'isRunning': false,
      'isPaused': false,
      'isInUse': false,
      'currentUserId': null,
      'currentSessionId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(userRef, {
      'depositLocked': 0,
      'currentSessionId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(commandRef, {
      'vehicleId': session.vehicleId,
      'sessionId': session.sessionId,
      'uid': session.uid,
      'type': 'end_ride',
      'status': kStatusPending,
      'source': 'mobile',
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(noticeRef, {
      'uid': session.uid,
      'target': 'user',
      'vehicleId': session.vehicleId,
      'sessionId': session.sessionId,
      'type': 'ride_ended',
      'title': '${session.vehicleName} đã kết thúc chuyến đi',
      'body': 'Cảm ơn bạn đã sử dụng xe.',
      'routeId': null,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /* --- private methods (persistence) --------------------------- */
  Future<void> _saveUserProfile(MobileUserProfile profile) async {
    final FirebaseFirestore? db = _db;
    if (db == null) return;
    await db.collection(kColUsers).doc(profile.uid).set({
      'uid': profile.uid,
      'employeeCode': profile.employeeCode,
      'fullName': profile.fullName,
      'phone': profile.phone,
      'email': profile.email,
      'role': profile.role,
      'balance': profile.balance,
      'depositLocked': profile.depositLocked,
      'isActive': profile.isActive,
      'currentSessionId': profile.currentSessionId,
      'createdAt': Timestamp.fromDate(profile.createdAt),
      'lastLoginAt': Timestamp.fromDate(profile.lastLoginAt),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _updateSessionStatus(
    UserRideSession session,
    String status,
  ) async {
    final DateTime now = DateTime.now();
    if (_db == null) {
      final UserRideSession next = UserRideSession(
        sessionId: session.sessionId,
        uid: session.uid,
        employeeCode: session.employeeCode,
        userName: session.userName,
        vehicleId: session.vehicleId,
        vehicleName: session.vehicleName,
        stationStartId: session.stationStartId,
        stationEndId: session.stationEndId,
        status: status,
        startedAt: session.startedAt,
        pausedAt: status == kStatusPaused ? now : null,
        endedAt: session.endedAt,
        lastHeartbeatAt: now,
        pricePerHour: session.pricePerHour,
        depositAmount: session.depositAmount,
        mainAmountUsed: session.mainAmountUsed,
        depositUsed: session.depositUsed,
        remainingBalanceSnapshot: session.remainingBalanceSnapshot,
        remainingSeconds: session.remainingSeconds,
        canUnlock: session.canUnlock,
        routeIds: session.routeIds,
      );
      _activeSessions[session.uid] = next;
      _demoSessions[session.uid]?.add(next);
      final RentalVehicle? vehicle = _vehicles[session.vehicleId];
      if (vehicle != null) {
        _vehicles[vehicle.id] = RentalVehicle(
          id: vehicle.id,
          name: vehicle.name,
          batteryPercent: vehicle.batteryPercent,
          isLocked: vehicle.isLocked,
          isRunning: status == kStatusActive,
          isPaused: status == kStatusPaused,
          isInUse: true,
          currentUserId: session.uid,
          currentSessionId: session.sessionId,
          totalKm: vehicle.totalKm,
          temp: vehicle.temp,
          hum: vehicle.hum,
          dust: vehicle.dust,
          lastLocation: vehicle.lastLocation,
          updatedAt: now,
        );
        _demoVehicles[vehicle.id]?.add(_vehicles[vehicle.id]);
      }
      return;
    }

    final WriteBatch batch = _db!.batch();
    batch.set(
      _db!.collection(kColRideSessions).doc(session.sessionId),
      {
        'status': status,
        'pausedAt': status == kStatusPaused ? Timestamp.fromDate(now) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      _db!.collection(kColVehicles).doc(session.vehicleId),
      {
        'isPaused': status == kStatusPaused,
        'isRunning': status == kStatusActive,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(_db!.collection(kColVehicleCommands).doc(), {
      'vehicleId': session.vehicleId,
      'sessionId': session.sessionId,
      'uid': session.uid,
      'type': status == kStatusPaused ? 'pause' : 'resume',
      'status': kStatusPending,
      'source': 'mobile',
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db!.collection(kColNotifications).doc(), {
      'uid': session.uid,
      'target': 'user',
      'vehicleId': session.vehicleId,
      'sessionId': session.sessionId,
      'type': status == kStatusPaused ? 'ride_paused' : 'ride_status',
      'title': status == kStatusPaused
          ? '${session.vehicleName} đang tạm ngưng'
          : '${session.vehicleName} tiếp tục sử dụng',
      'body': status == kStatusPaused
          ? 'Bạn có thể tiếp tục bất cứ lúc nào.'
          : 'Chuyến đi đang tiếp tục.',
      'routeId': null,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /* --- private methods (doc -> model) -------------------------- */
  MobileUserProfile _profileFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> m = doc.data() ?? {};
    return MobileUserProfile(
      uid: (m['uid'] ?? doc.id).toString(),
      employeeCode: (m['employeeCode'] ?? 'NV001').toString(),
      fullName: (m['fullName'] ?? 'Người dùng').toString(),
      phone: m['phone']?.toString(),
      email: m['email']?.toString(),
      role: (m['role'] ?? 'user').toString(),
      balance: _asInt(m['balance'], 0),
      depositLocked: _asInt(m['depositLocked'], 0),
      isActive: _asBool(m['isActive'], true),
      currentSessionId: m['currentSessionId']?.toString(),
      createdAt: _asDate(m['createdAt']),
      lastLoginAt: _asDate(m['lastLoginAt']),
    );
  }

  BikeStation _stationFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> m = doc.data() ?? {};
    final Map<String, dynamic> loc =
        (m['location'] as Map?)?.cast<String, dynamic>() ?? {};
    final double lat = (loc['lat'] as num?)?.toDouble() ?? 0;
    final double lon = (loc['lon'] as num?)?.toDouble() ?? 0;
    return BikeStation(
      id: (m['id'] ?? doc.id).toString(),
      name: (m['name'] ?? '').toString(),
      city: (m['city'] ?? '').toString(),
      address: (m['address'] ?? '').toString(),
      point: LatLng(lat, lon),
      googleMapUrl: (m['googleMapUrl'] ?? '').toString(),
      bikeCount: _asInt(m['bikeCount'], 0),
      availableSlots: _asInt(m['availableSlots'], 0),
      isActive: _asBool(m['isActive'], true),
    );
  }

  UserRideSession _sessionFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> m = doc.data() ?? {};
    return UserRideSession(
      sessionId: (m['sessionId'] ?? doc.id).toString(),
      uid: (m['uid'] ?? '').toString(),
      employeeCode: (m['employeeCode'] ?? '').toString(),
      userName: (m['userName'] ?? '').toString(),
      vehicleId: (m['vehicleId'] ?? '').toString(),
      vehicleName: (m['vehicleName'] ?? '').toString(),
      stationStartId: m['stationStartId']?.toString(),
      stationEndId: m['stationEndId']?.toString(),
      status: (m['status'] ?? kStatusPending).toString(),
      startedAt: _asDate(m['startedAt']),
      pausedAt: m['pausedAt'] == null ? null : _asDate(m['pausedAt']),
      endedAt: m['endedAt'] == null ? null : _asDate(m['endedAt']),
      lastHeartbeatAt: _asDate(m['lastHeartbeatAt']),
      pricePerHour: _asInt(m['pricePerHour'], kDefaultPricePerHour),
      depositAmount: _asInt(m['depositAmount'], kDefaultDepositAmount),
      mainAmountUsed: _asInt(m['mainAmountUsed'], 0),
      depositUsed: _asInt(m['depositUsed'], 0),
      remainingBalanceSnapshot: _asInt(m['remainingBalanceSnapshot'], 0),
      remainingSeconds: _asInt(m['remainingSeconds'], 0),
      canUnlock: _asBool(m['canUnlock'], true),
      routeIds: ((m['routeIds'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  RentalVehicle _vehicleFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> m = doc.data() ?? {};
    final Map<String, dynamic> loc =
        (m['lastLocation'] as Map?)?.cast<String, dynamic>() ?? {};
    return RentalVehicle(
      id: (m['id'] ?? doc.id).toString(),
      name: (m['name'] ?? '').toString(),
      batteryPercent: _asInt(m['batteryPercent'], 0),
      isLocked: _asBool(m['isLocked'], true),
      isRunning: _asBool(m['isRunning'], false),
      isPaused: _asBool(m['isPaused'], false),
      isInUse: _asBool(m['isInUse'], false),
      currentUserId: m['currentUserId']?.toString(),
      currentSessionId: m['currentSessionId']?.toString(),
      totalKm: _asDouble(m['totalKm'], 0),
      temp: _asDouble(m['temp'], 0),
      hum: _asDouble(m['hum'], 0),
      dust: _asDouble(m['dust'], 0),
      lastLocation: LatLng(_asDouble(loc['lat'], 0), _asDouble(loc['lon'], 0)),
      updatedAt: _asDate(m['updatedAt']),
    );
  }

  UserNotice _noticeFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> m = doc.data() ?? {};
    return UserNotice(
      id: doc.id,
      title: (m['title'] ?? '').toString(),
      body: (m['body'] ?? '').toString(),
      type: (m['type'] ?? 'system').toString(),
      vehicleId: m['vehicleId']?.toString(),
      sessionId: m['sessionId']?.toString(),
      routeId: m['routeId']?.toString(),
      isRead: _asBool(m['isRead'], false),
      createdAt: _asDate(m['createdAt']),
    );
  }

  MobileHistoryRoute _routeFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> m = doc.data() ?? {};
    final List rawPoints = (m['points'] as List?) ?? const [];
    final List<LatLng> points = rawPoints.map((e) {
      final Map<String, dynamic> p = Map<String, dynamic>.from(e as Map);
      return LatLng(_asDouble(p['lat'], 0), _asDouble(p['lon'], 0));
    }).toList();
    return MobileHistoryRoute(
      id: doc.id,
      vehicleId: (m['vehicleId'] ?? '').toString(),
      startAt: _asDate(m['startAt']),
      endAt: m['endAt'] == null ? null : _asDate(m['endAt']),
      points: points,
    );
  }

  /* --- private methods (seed / demo helpers) ------------------- */
  List<UserNotice> _seedNotices(String uid) {
    final UserRideSession? session = _activeSessions[uid];
    final List<UserNotice> items = <UserNotice>[];
    if (session != null) {
      items.add(
        UserNotice(
          id: 'n1',
          title: '${session.vehicleName} đang được sử dụng',
          body: 'Còn khoảng ${session.remainingSeconds ~/ 60} phút sử dụng.',
          type: 'ride_status',
          vehicleId: session.vehicleId,
          sessionId: session.sessionId,
          routeId: null,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );
    }
    items.add(
      UserNotice(
        id: 'n2',
        title: 'Cảnh báo pin thấp',
        body: 'Nếu xe còn dưới 20% pin, app sẽ nhắc bạn trả xe.',
        type: 'battery_low',
        vehicleId: 'V1',
        sessionId: null,
        routeId: null,
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    );
    return items;
  }

  List<MobileHistoryRoute> _seedRoutes(String vehicleId) {
    return [
      MobileHistoryRoute(
        id: 'r1',
        vehicleId: vehicleId,
        startAt: DateTime.now().subtract(const Duration(hours: 2)),
        endAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
        points: const [
          LatLng(10.7791, 106.6998),
          LatLng(10.7780, 106.7041),
          LatLng(10.7760, 106.6942),
        ],
      ),
    ];
  }

  MobileUserProfile _demoProfileFromAccount(_DemoAccount account) {
    return MobileUserProfile(
      uid: account.uid,
      employeeCode: account.employeeCode,
      fullName: account.fullName,
      phone: account.phone,
      email: account.email,
      role: 'user',
      balance: account.balance,
      depositLocked: 0,
      isActive: true,
      currentSessionId: _activeSessions[account.uid]?.sessionId,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastLoginAt: DateTime.now(),
    );
  }

  void _replaceDemoAccount(_DemoAccount account) {
    if (account.email != null) _demoAccounts[account.email!] = account;
    if (account.phone != null) _demoAccounts[account.phone!] = account;
  }

  void _pushDemoProfile(MobileUserProfile profile) {
    final StreamController<MobileUserProfile> ctl = _demoProfiles.putIfAbsent(
      profile.uid,
      () => StreamController<MobileUserProfile>.broadcast(),
    );
    if (!ctl.isClosed) ctl.add(profile);
  }

  /* --- private methods (type conversion helpers) --------------- */
  bool _asBool(dynamic value, bool fallback) {
    if (value is bool) return value;
    if (value == null) return fallback;
    return value.toString().toLowerCase() == 'true';
  }

  int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _asDouble(dynamic value, double fallback) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  DateTime _asDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}

/* Private classes ---------------------------------------------------- */
class _DemoAccount {
  final String uid;
  final String? email;
  final String? phone;
  final String password;
  final String employeeCode;
  final String fullName;
  final int balance;

  const _DemoAccount({
    required this.uid,
    required this.email,
    required this.phone,
    required this.password,
    required this.employeeCode,
    required this.fullName,
    required this.balance,
  });

  _DemoAccount copyWith({String? password, int? balance}) {
    return _DemoAccount(
      uid: uid,
      email: email,
      phone: phone,
      password: password ?? this.password,
      employeeCode: employeeCode,
      fullName: fullName,
      balance: balance ?? this.balance,
    );
  }
}

/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
