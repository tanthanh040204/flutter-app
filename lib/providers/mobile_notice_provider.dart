/*
 * @file       mobile_notice_provider.dart
 * @brief      Streams per-user notifications and history routes.
 */

/* Imports ------------------------------------------------------------ */
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/mobile_history_route.dart';
import '../models/user_notice.dart';
import '../services/mobile_user_repo.dart';

/* Constants ---------------------------------------------------------- */
const String kDefaultVehicleId = 'V1';

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class MobileNoticeProvider extends ChangeNotifier {
  MobileNoticeProvider(this._repo);

  /* --- private fields ------------------------------------------ */
  final MobileUserRepo _repo;
  StreamSubscription<List<UserNotice>>? _noticeSub;
  StreamSubscription<List<MobileHistoryRoute>>? _routeSub;

  /* --- public fields ------------------------------------------- */
  List<UserNotice> notices = const [];
  List<MobileHistoryRoute> routes = const [];

  /* --- public methods ------------------------------------------ */
  void bindUser(String? uid, {String vehicleId = kDefaultVehicleId}) {
    _noticeSub?.cancel();
    _routeSub?.cancel();
    notices = const [];
    routes = const [];
    notifyListeners();
    if (uid == null) return;

    _noticeSub = _repo.watchUserNotifications(uid).listen((event) {
      notices = event;
      notifyListeners();
    });
    _routeSub = _repo.watchUserRoutes(vehicleId: vehicleId).listen((event) {
      routes = event;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _noticeSub?.cancel();
    _routeSub?.cancel();
    super.dispose();
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
