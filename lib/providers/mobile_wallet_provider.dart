/*
 * @file       mobile_wallet_provider.dart
 * @brief      Handles REQ_ADD_TOKEN / RESP_ADD_TOKEN_* via MQTT, plus the
 *             login-time balance + debt sync that gates the main UI.
 */

/* Imports ------------------------------------------------------------ */
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/feature_conf.dart';
import '../config/mqtt_config.dart';
import '../models/error_codes.dart';
import '../models/mobile_user_profile.dart';
import '../services/mobile_user_repo.dart';
import '../services/mqtt_service.dart';
import '../services/protocol_codec.dart';
import '../services/user_wire_id.dart';
import 'mobile_auth_provider.dart';
import 'mobile_ride_provider.dart';

/* Constants ---------------------------------------------------------- */
const Duration kTopupResponseTimeout = Duration(
  seconds: FeatureConfig.topupResponseTimeoutSeconds,
);
const Duration kBalanceSyncTimeout = Duration(
  seconds: FeatureConfig.topupResponseTimeoutSeconds,
);

/* Enums -------------------------------------------------------------- */

enum TopupPhase { idle, requesting, success, error }

// Login-time money sync: the app blocks its main UI until the authoritative
// balance + debt is fetched from the web (or the user retries; skipped in
// local mode where there is no web).
enum MoneySyncState { idle, syncing, synced, failed }

/* Typedef / Function types ------------------------------------------ */
/* Public classes ----------------------------------------------------- */

class MobileWalletProvider extends ChangeNotifier {
  MobileWalletProvider(this._mqtt, this._repo) {
    _mqtt.addListener(_onMqttChanged);
  }

  /* --- private fields ------------------------------------------ */
  final MqttService _mqtt;
  final MobileUserRepo _repo;
  // Wired in main.dart so synced money lands in the providers the UI reads.
  MobileAuthProvider? _auth;
  MobileRideProvider? _ride;
  StreamSubscription<ProtocolMessage>? _responseSub;
  Timer? _requestTimeout;
  Timer? _syncTimeout;
  bool _needBalanceSync = false;
  String? _uid;
  String? _wireUserId;

  /* --- public fields ------------------------------------------- */
  TopupPhase phase = TopupPhase.idle;
  int? latestBalance;
  String? lastError;

  // Login-time money sync state (gates the main UI in MobileBootstrap).
  MoneySyncState syncState = MoneySyncState.idle;
  int? syncedBalance;
  int syncedDebt = 0;

  /* --- public getters ------------------------------------------ */
  bool get isBalanceSynced => syncState == MoneySyncState.synced;
  bool get hasDebt => syncedDebt > 0;

  /* --- public methods ------------------------------------------ */
  void attachAuth(MobileAuthProvider auth) => _auth = auth;
  void attachRide(MobileRideProvider ride) => _ride = ride;

  void bindUser(MobileUserProfile? user) {
    final String? uid = user?.uid;
    final String? wireUserId = user == null
        ? null
        : buildWireUserId(uid: user.uid, phone: user.phone, email: user.email);
    if (_uid == uid && _wireUserId == wireUserId) return;
    _uid = uid;
    _wireUserId = wireUserId;
    _responseSub?.cancel();
    _requestTimeout?.cancel();
    _requestTimeout = null;
    _syncTimeout?.cancel();
    _syncTimeout = null;
    _responseSub = null;
    phase = TopupPhase.idle;
    latestBalance = null;
    lastError = null;
    _needBalanceSync = false;
    syncedBalance = null;
    syncedDebt = 0;
    syncState = MoneySyncState.idle;
    if (wireUserId != null) {
      _responseSub = _mqtt
          .streamOf(MqttTopics.userResponse(wireUserId))
          .listen(_handleResponse);
      _startBalanceSync();
    }
    notifyListeners();
  }

  /* User-triggered retry from the sync screen. */
  void retryBalanceSync() => _startBalanceSync();

  bool requestAddToken({required int amount}) {
    if (_uid == null || _wireUserId == null) {
      lastError = kErrAccountInvalid;
      phase = TopupPhase.error;
      notifyListeners();
      return false;
    }
    if (amount <= 0) {
      lastError = kErrTopupAmountInvalid;
      phase = TopupPhase.error;
      notifyListeners();
      return false;
    }
    phase = TopupPhase.requesting;
    lastError = null;
    notifyListeners();
    _requestTimeout?.cancel();
    _requestTimeout = Timer(kTopupResponseTimeout, () {
      if (phase != TopupPhase.requesting) return;
      phase = TopupPhase.error;
      lastError = kErrTopupFailed;
      if (FeatureConfig.debugWalletLog) {
        debugPrint(
          '[Wallet] topup timeout after ${kTopupResponseTimeout.inSeconds}s '
          'without RESP_ADD_TOKEN_*',
        );
      }
      notifyListeners();
    });

    final bool ok = _mqtt.publish(
      kTopicAddTokenRequest,
      ProtocolCodec.build(kCmdReqAddToken, [_wireUserId!, amount.toString()]),
    );
    if (!ok) {
      _requestTimeout?.cancel();
      _requestTimeout = null;
      phase = TopupPhase.error;
      lastError = kErrTopupFailed;
      notifyListeners();
    }
    return ok;
  }

  void resetStatus() {
    _requestTimeout?.cancel();
    _requestTimeout = null;
    phase = TopupPhase.idle;
    lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _mqtt.removeListener(_onMqttChanged);
    _requestTimeout?.cancel();
    _syncTimeout?.cancel();
    _responseSub?.cancel();
    super.dispose();
  }

  /* --- private methods ----------------------------------------- */

  void _startBalanceSync() {
    if (_wireUserId == null) return;
    if (_repo.isLocalMode) {
      syncState = MoneySyncState.synced;
      notifyListeners();
      return;
    }
    _needBalanceSync = true;
    syncState = MoneySyncState.syncing;
    _syncTimeout?.cancel();
    _syncTimeout = Timer(kBalanceSyncTimeout, () {
      if (syncState != MoneySyncState.syncing) return;
      syncState = MoneySyncState.failed;
      if (FeatureConfig.debugWalletLog) {
        debugPrint('[Wallet] balance sync timeout — awaiting retry');
      }
      notifyListeners();
    });
    _sendBalanceQuery();
    notifyListeners();
  }

  void _sendBalanceQuery() {
    final String? wireUserId = _wireUserId;
    if (wireUserId == null || !_needBalanceSync) return;
    final bool ok = _mqtt.publish(
      kTopicAddTokenRequest,
      ProtocolCodec.build(kCmdQueryBalance, [wireUserId]),
    );
    if (FeatureConfig.debugWalletLog) {
      debugPrint('[Wallet] QUERY_BALANCE sent published=$ok');
    }
    // If not connected yet, _onMqttChanged resends once the link is up.
  }

  void _onMqttChanged() {
    if (_needBalanceSync && _mqtt.isConnected) {
      _sendBalanceQuery();
    }
  }

  void _onBalanceSynced(ProtocolMessage msg) {
    _needBalanceSync = false;
    _syncTimeout?.cancel();
    _syncTimeout = null;
    final int? balance = int.tryParse(msg.argAt(0) ?? '');
    syncedDebt = int.tryParse(msg.argAt(1) ?? '') ?? 0;
    if (balance != null) {
      syncedBalance = balance;
      latestBalance = balance;
      _auth?.updateLocalBalance(balance); // instant UI update
      _applyBalanceToProfile(balance); // persist so the profile stream agrees
    }
    // Debt is shown via MobileRideProvider.debtAmount; keep them in sync.
    _ride?.setExternalDebt(syncedDebt);
    syncState = MoneySyncState.synced;
    if (FeatureConfig.debugWalletLog) {
      debugPrint('[Wallet] balance synced: balance=$balance debt=$syncedDebt');
    }
    notifyListeners();
  }

  /* Reconcile the locally-shown balance (users/{uid}) with the web's value so
   * the profile stream propagates it to every screen. */
  void _applyBalanceToProfile(int balance) {
    final String? uid = _uid;
    if (uid == null) return;
    unawaited(_repo.setUserBalance(uid, balance));
  }

  void _handleResponse(ProtocolMessage msg) {
    switch (msg.command) {
      case kEvtRespBalance:
        _onBalanceSynced(msg);
        break;
      case kEvtRespAddTokenSuccess:
        _requestTimeout?.cancel();
        _requestTimeout = null;
        latestBalance = int.tryParse(msg.argAt(0) ?? '');
        phase = TopupPhase.success;
        // A successful top-up also carries the latest authoritative balance.
        if (latestBalance != null) {
          syncedBalance = latestBalance;
          _applyBalanceToProfile(latestBalance!);
        }
        notifyListeners();
        break;
      case kEvtRespAddTokenError:
        _requestTimeout?.cancel();
        _requestTimeout = null;
        lastError = msg.argAt(0) ?? kErrUnknown;
        phase = TopupPhase.error;
        // The same error answers a QUERY_BALANCE for an unknown user.
        if (_needBalanceSync && syncState == MoneySyncState.syncing) {
          _needBalanceSync = false;
          _syncTimeout?.cancel();
          _syncTimeout = null;
          syncState = MoneySyncState.failed;
        }
        notifyListeners();
        break;
    }
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
