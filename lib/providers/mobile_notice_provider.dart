/*
 * @file       mobile_notice_provider.dart
 * @brief      Streams per-user notifications.
 */

/* Imports ------------------------------------------------------------ */
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user_notice.dart';
import '../services/mobile_user_repo.dart';

/* Constants ---------------------------------------------------------- */
const String kNoticeTypeStolen = 'theft_alert';

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class MobileNoticeProvider extends ChangeNotifier {
  MobileNoticeProvider(this._repo);

  /* --- private fields ------------------------------------------ */
  final MobileUserRepo _repo;
  StreamSubscription<List<UserNotice>>? _noticeSub;
  String? _uid;
  /* App-generated alerts (e.g. theft) kept separate so the remote
   * stream re-emitting does not wipe them. */
  final List<UserNotice> _localNotices = [];
  List<UserNotice> _remoteNotices = const [];
  /* Ids of remote notices the user dismissed locally — filtered out so the
   * re-emitting stream doesn't resurrect them (no Firestore delete). */
  final Set<String> _dismissedIds = {};

  /* --- public getters ------------------------------------------ */
  List<UserNotice> get notices => [
    ..._localNotices,
    ..._remoteNotices.where((n) => !_dismissedIds.contains(n.id)),
  ];

  /* --- public methods ------------------------------------------ */
  void bindUser(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _noticeSub?.cancel();
    _localNotices.clear();
    _remoteNotices = const [];
    _dismissedIds.clear();
    notifyListeners();
    if (uid == null) return;

    _noticeSub = _repo.watchUserNotifications(uid).listen((event) {
      _remoteNotices = event;
      notifyListeners();
    });
  }

  /* Surface a theft alert in the notifications tab. Deduped per bike so
   * repeated NOTI_STOLEN messages don't stack up. */
  void pushStolenAlert(String bikeId) {
    final bool exists = _localNotices.any(
      (n) => n.type == kNoticeTypeStolen && n.vehicleId == bikeId,
    );
    if (exists) return;
    _localNotices.insert(
      0,
      UserNotice(
        id: 'stolen-$bikeId',
        title: '',
        body: '',
        type: kNoticeTypeStolen,
        vehicleId: bikeId,
        sessionId: null,
        routeId: null,
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /* Remove a notice from the tab locally. Local alerts are dropped outright;
   * remote ones are suppressed by id (Firestore is left untouched). */
  void deleteNotice(String id) {
    final int before = _localNotices.length;
    _localNotices.removeWhere((n) => n.id == id);
    if (_localNotices.length == before) _dismissedIds.add(id);
    notifyListeners();
  }

  @override
  void dispose() {
    _noticeSub?.cancel();
    super.dispose();
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
