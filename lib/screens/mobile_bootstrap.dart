/*
 * @file       mobile_bootstrap.dart
 * @brief      Root router: onboarding / login / home. Also drives the MQTT
 *             connection lifecycle based on auth state.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/feature_conf.dart';
import '../providers/mobile_auth_provider.dart';
import '../providers/mobile_wallet_provider.dart';
import '../services/mqtt_service.dart';
import '../services/user_wire_id.dart';
import 'home_mobile_shell.dart';
import 'login_register_screen.dart';
import 'onboarding_screen.dart';

/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class MobileBootstrap extends StatefulWidget {
  const MobileBootstrap({super.key});

  @override
  State<MobileBootstrap> createState() => _MobileBootstrapState();
}

/* Private classes ---------------------------------------------------- */
class _MobileBootstrapState extends State<MobileBootstrap> {
  String? _connectedUid;
  MobileAuthProvider? _auth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final MobileAuthProvider nextAuth = context.read<MobileAuthProvider>();
    if (!identical(_auth, nextAuth)) {
      _auth?.removeListener(_onAuthChanged);
      _auth = nextAuth;
      _auth!.addListener(_onAuthChanged);
      _syncMqttConnection(_auth!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MobileAuthProvider auth = context.watch<MobileAuthProvider>();

    if (auth.showOnboarding) {
      return const OnboardingScreen();
    }

    if (!auth.isLoggedIn) {
      return const LoginRegisterScreen();
    }

    // Block the main UI until the authoritative balance + debt is synced from
    // the web (skipped in local mode, where the wallet marks it synced at once).
    final MobileWalletProvider wallet = context.watch<MobileWalletProvider>();
    if (wallet.syncState != MoneySyncState.synced) {
      return _MoneySyncScreen(
        failed: wallet.syncState == MoneySyncState.failed,
        onRetry: () => context.read<MobileWalletProvider>().retryBalanceSync(),
      );
    }

    return const HomeMobileShell();
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    final MobileAuthProvider? auth = _auth;
    if (!mounted || auth == null) return;
    _syncMqttConnection(auth);
  }

  void _syncMqttConnection(MobileAuthProvider auth) {
    final user = auth.currentUser;
    final String? uid = user?.uid;
    final MqttService service = context.read<MqttService>();

    if (uid == null && _connectedUid != null) {
      if (FeatureConfig.debugMqttLog) {
        debugPrint('[MQTT][Bootstrap] logout detected, disconnect MQTT');
      }
      _connectedUid = null;
      service.disconnect();
      return;
    }

    if (uid != null && _connectedUid != uid) {
      final String clientId = buildWireUserId(
        uid: uid,
        phone: user?.phone,
        email: user?.email,
      );
      if (FeatureConfig.debugMqttLog) {
        debugPrint(
          '[MQTT][Bootstrap] login detected, start connect: '
          'uid=$uid clientId=$clientId',
        );
      }
      _connectedUid = uid;
      service.connect(clientId: clientId).then((bool ok) {
        if (FeatureConfig.debugMqttLog) {
          debugPrint(
            '[MQTT][Bootstrap] connect done: '
            'uid=$uid clientId=$clientId ok=$ok state=${service.state}',
          );
        }
      });
    }
  }
}

// Loading gate shown after login while the balance + debt is synced from the
// web. On failure (web/MQTT unreachable) it offers a retry instead of entering
// the app with possibly-stale money.
class _MoneySyncScreen extends StatelessWidget {
  const _MoneySyncScreen({required this.failed, required this.onRetry});

  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: failed
                ? [
                    const Icon(Icons.cloud_off, size: 56),
                    const SizedBox(height: 16),
                    const Text(
                      'Could not sync your balance.\nCheck your connection and try again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ]
                : const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Syncing your balance…'),
                  ],
          ),
        ),
      ),
    );
  }
}

/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
