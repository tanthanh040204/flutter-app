import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/mobile_auth_provider.dart';
import '../services/mobile_user_repo.dart';

class WalletTopupScreen extends StatefulWidget {
  const WalletTopupScreen({super.key});

  @override
  State<WalletTopupScreen> createState() => _WalletTopupScreenState();
}

class _WalletTopupScreenState extends State<WalletTopupScreen> {
  final amountCtl = TextEditingController(text: '50000');
  bool loading = false;

  @override
  void dispose() {
    amountCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<MobileAuthProvider>().currentUser;
    final uid = user?.uid ?? 'unknown';
    final transferContent = 'NAPTIEN_$uid';

    return Scaffold(
      appBar: AppBar(title: const Text('Nạp tiền')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Chuyển khoản theo QR bên dưới', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Center(
            child: QrImageView(
              data: 'bank://MB/0123456789/CONG TY ABC/$transferContent',
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
                  Text('Ngân hàng: UTE Bank'),
                  Text('Số tài khoản: 0123456789'),
                  Text('Tên tài khoản: CONG TY UTE'),
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
                        const SnackBar(content: Text('Đã tạo yêu cầu nạp tiền.')),
                      );
                    } finally {
                      if (mounted) setState(() => loading = false);
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(loading ? 'Đang xử lý...' : 'Tôi đã chuyển khoản'),
            ),
          )
        ],
      ),
    );
  }
}
