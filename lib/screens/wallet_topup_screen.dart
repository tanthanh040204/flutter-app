/*
 * @file       wallet_topup_screen.dart
 * @brief      Wallet top-up screen. Publishes REQ_ADD_TOKEN over MQTT and
 *             reflects the RESP_ADD_TOKEN_* response back to the user.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/app_strings.dart';
import '../models/error_codes.dart';
import '../providers/mobile_auth_provider.dart';
import '../providers/mobile_ride_provider.dart';
import '../providers/mobile_wallet_provider.dart';
import '../config/feature_conf.dart';

/* Constants ---------------------------------------------------------- */
const String kDefaultTopupAmount = '50000';
const String kTopupPrefix = 'NAPTIEN_';
const String kUnknownUid = 'unknown';
const String kBankName = 'UTE Bank';
const String kBankAccount = '0123456789';
const String kBankAccountHolder = 'CONG TY UTE';
const String kBankCode = 'MB';
const String kBankTransferCompany = 'CONG TY ABC';

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class WalletTopupScreen extends StatefulWidget {
  const WalletTopupScreen({super.key});

  @override
  State<WalletTopupScreen> createState() => _WalletTopupScreenState();
}

/* Private classes ---------------------------------------------------- */
class _WalletTopupScreenState extends State<WalletTopupScreen> {
  final TextEditingController amountCtl = TextEditingController(
    text: kDefaultTopupAmount,
  );
  int? _lastAppliedBalance;

  @override
  void dispose() {
    amountCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings t = context.tr;
    final user = context.watch<MobileAuthProvider>().currentUser;
    final MobileWalletProvider wallet = context.watch<MobileWalletProvider>();
    final String uid = user?.uid ?? kUnknownUid;
    final String transferContent = '$kTopupPrefix$uid';
    bool requesting = false;
    if (!FeatureConfig.enableDebugAddToken) {
      requesting = wallet.phase == TopupPhase.requesting;
    } else {
      requesting = true;
    }

    _handleStatusSideEffects(wallet);

    return Scaffold(
      appBar: AppBar(title: Text(t.topUp)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            t.topUpByQr,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Center(
            child: QrImageView(
              data:
                  'bank://$kBankCode/$kBankAccount/$kBankTransferCompany/$transferContent',
              size: 220,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.bank),
                  Text(t.accountNumber),
                  Text(t.accountName),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountCtl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: t.topUpAmount),
          ),
          const SizedBox(height: 12),
          SelectableText(t.memo(transferContent)),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: requesting || user == null
                ? null
                : () {
                    final int amount = int.tryParse(amountCtl.text) ?? 0;
                    wallet.requestAddToken(amount: amount);
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(requesting ? t.processing : t.transferred),
            ),
          ),
          if (wallet.phase == TopupPhase.success &&
              wallet.latestBalance != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Card(
                color: Colors.green.shade50,
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(t.topUpSuccessful),
                  subtitle: Text(t.newBalance('${wallet.latestBalance}${t.moneySymbol}')),
                ),
              ),
            ),
          if (wallet.phase == TopupPhase.error && wallet.lastError != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Card(
                color: Colors.red.shade50,
                child: ListTile(
                  leading: const Icon(Icons.error, color: Colors.red),
                  title: Text(t.topUpFailed),
                  subtitle: Text(t.errorDescription(wallet.lastError!)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleStatusSideEffects(MobileWalletProvider wallet) {
    if (wallet.phase != TopupPhase.success) return;
    final int? balance = wallet.latestBalance;
    if (balance == null) return;
    if (_lastAppliedBalance == balance) return;
    _lastAppliedBalance = balance;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MobileAuthProvider>().updateLocalBalance(balance);
      context.read<MobileRideProvider>().clearDebt();
    });
  }
}

/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
