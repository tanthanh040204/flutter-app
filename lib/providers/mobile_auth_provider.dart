import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/mobile_user_profile.dart';
import '../services/mobile_user_repo.dart';

class MobileAuthProvider extends ChangeNotifier {
  MobileAuthProvider(this._repo);

  final MobileUserRepo _repo;
  MobileUserProfile? _currentUser;
  StreamSubscription<MobileUserProfile?>? _profileSub;
  bool _loading = false;
  bool _showOnboarding = true;
  String? _error;

  MobileUserProfile? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get loading => _loading;
  bool get showOnboarding => _showOnboarding;
  String? get error => _error;

  void finishOnboarding() {
    _showOnboarding = false;
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final user = await _repo.signIn(email: email, password: password);
      await _bindProfile(user.uid);
      _currentUser = user;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final user = await _repo.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
      );
      await _bindProfile(user.uid);
      _currentUser = user;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _currentUser;
    if (user == null) throw Exception('Bạn chưa đăng nhập.');
    await _repo.changePassword(
      uid: user.uid,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> logout() async {
    await _repo.signOut();
    await _profileSub?.cancel();
    _profileSub = null;
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _bindProfile(String uid) async {
    await _profileSub?.cancel();
    _profileSub = _repo.watchUserProfile(uid).listen((profile) {
      if (profile != null) {
        _currentUser = profile;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }
}
