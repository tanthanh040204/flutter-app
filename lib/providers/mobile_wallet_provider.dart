/*
 * @file       mobile_wallet_provider.dart
 * @brief      Handles REQ_ADD_TOKEN / RESP_ADD_TOKEN_* via MQTT.
 */

/* Imports ------------------------------------------------------------ */
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/mqtt_config.dart';
import '../models/error_codes.dart';
import '../models/mobile_user_profile.dart';
import '../services/mqtt_service.dart';
import '../services/protocol_codec.dart';
import '../services/user_wire_id.dart';

/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */

enum TopupPhase { idle, requesting, success, error }

const Duration kTopupResponseTimeout = Duration(seconds: 20);

/* Typedef / Function types ------------------------------------------ */
/* Public classes ----------------------------------------------------- */

class MobileWalletProvider extends ChangeNotifier {
  MobileWalletProvider(this._mqtt);

  /* --- private fields ------------------------------------------ */
  final MqttService                       _mqtt;
  StreamSubscription<ProtocolMessage>?    _responseSub;
  Timer?                                  _requestTimeout;
  String?                                 _uid;
  String?                                 _wireUserId;

  /* --- public fields ------------------------------------------- */
  TopupPhase phase         = TopupPhase.idle;
  int?       latestBalance;
  String?    lastError;

  /* --- public methods ------------------------------------------ */
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
    _responseSub = null;
    phase         = TopupPhase.idle;
    latestBalance = null;
    lastError     = null;
    if (wireUserId != null) {
      _responseSub = _mqtt
          .streamOf(MqttTopics.userResponse(wireUserId))
          .listen(_handleResponse);
    }
    notifyListeners();
  }

  bool requestAddToken({required int amount}) {
    if (_uid == null || _wireUserId == null) {
      lastError = kErrAccountInvalid;
      phase     = TopupPhase.error;
      notifyListeners();
      return false;
    }
    if (amount <= 0) {
      lastError = kErrTopupAmountInvalid;
      phase     = TopupPhase.error;
      notifyListeners();
      return false;
    }
    phase     = TopupPhase.requesting;
    lastError = null;
    notifyListeners();
    _requestTimeout?.cancel();
    _requestTimeout = Timer(kTopupResponseTimeout, () {
      if (phase != TopupPhase.requesting) return;
      phase = TopupPhase.error;
      lastError = kErrTopupFailed;
      debugPrint(
        '[Wallet] topup timeout after ${kTopupResponseTimeout.inSeconds}s '
        'without RESP_ADD_TOKEN_*',
      );
      notifyListeners();
    });

    final bool ok = _mqtt.publish(
      kTopicAddTokenRequest,
      ProtocolCodec.build(kCmdReqAddToken, [_wireUserId!, amount.toString()]),
    );
    if (!ok) {
      _requestTimeout?.cancel();
      _requestTimeout = null;
      phase     = TopupPhase.error;
      lastError = kErrTopupFailed;
      notifyListeners();
    }
    return ok;
  }

  void resetStatus() {
    _requestTimeout?.cancel();
    _requestTimeout = null;
    phase     = TopupPhase.idle;
    lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _requestTimeout?.cancel();
    _responseSub?.cancel();
    super.dispose();
  }

  /* --- private methods ----------------------------------------- */
  void _handleResponse(ProtocolMessage msg) {
    _requestTimeout?.cancel();
    _requestTimeout = null;
    switch (msg.command) {
      case kEvtRespAddTokenSuccess:
        latestBalance = int.tryParse(msg.argAt(0) ?? '');
        phase         = TopupPhase.success;
        notifyListeners();
        break;
      case kEvtRespAddTokenError:
        lastError = msg.argAt(0) ?? kErrUnknown;
        phase     = TopupPhase.error;
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
