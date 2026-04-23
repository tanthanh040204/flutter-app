/*
 * @file       wallet_topup_screen.dart
 * @brief      Wallet top-up screen that shows a bank-transfer QR code.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/mobile_auth_provider.dart';
import '../services/mobile_user_repo.dart';

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
  bool loading = false;

  @override
  void dispose() {
    amountCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<MobileAuthProvider>().currentUser;
    final String uid = user?.uid ?? kUnknownUid;
    final String transferContent = '$kTopupPrefix$uid';

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
            onPressed: loading || user == null
                ? null
                : () async {
                    setState(() => loading = true);
                    try {
                      await context.read<MobileUserRepo>().createTopupRequest(
                        uid: user.uid,
                        amount: int.tryParse(amountCtl.text) ?? 0,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã tạo yêu cầu nạp tiền.'),
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => loading = false);
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(loading ? 'Đang xử lý...' : 'Tôi đã chuyển khoản'),
            ),
          ),
        ],
      ),
    );
  }
}

/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
