import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/mobile_history_route.dart';
import '../models/user_notice.dart';
import '../services/mobile_user_repo.dart';

class MobileNoticeProvider extends ChangeNotifier {
  MobileNoticeProvider(this._repo);

  final MobileUserRepo _repo;
  StreamSubscription<List<UserNotice>>? _noticeSub;
  StreamSubscription<List<MobileHistoryRoute>>? _routeSub;
  List<UserNotice> notices = const [];
  List<MobileHistoryRoute> routes = const [];

  void bindUser(String? uid, {String vehicleId = 'haq-trk-003'}) {
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
