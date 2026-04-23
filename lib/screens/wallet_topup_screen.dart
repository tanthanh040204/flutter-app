/*
 * @file       wallet_topup_screen.dart
 * @brief      Wallet top-up screen. Publishes REQ_ADD_TOKEN over MQTT and
 *             reflects the RESP_ADD_TOKEN_* response back to the user.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/error_codes.dart';
import '../providers/mobile_auth_provider.dart';
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
      appBar: AppBar(title: const Text('Nạp tiền')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Chuyển khoản theo QR bên dưới',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
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
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ngân hàng: $kBankName'),
                  Text('Số tài khoản: $kBankAccount'),
                  Text('Tên tài khoản: $kBankAccountHolder'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountCtl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Số tiền cần nạp'),
          ),
          const SizedBox(height: 12),
          SelectableText('Nội dung: $transferContent'),
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
              child: Text(requesting ? 'Đang xử lý...' : 'Tôi đã chuyển khoản'),
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
                  title: const Text('Nạp tiền thành công'),
                  subtitle: Text('Số dư mới: ${wallet.latestBalance}đ'),
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
                  title: const Text('Nạp tiền thất bại'),
                  subtitle: Text(ErrorMessages.describe(wallet.lastError!)),
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
    });
  }
}

/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
