import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/app_strings.dart';
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
    final t = context.tr;
    final user = context.watch<MobileAuthProvider>().currentUser;
    final uid = user?.uid ?? 'unknown';
    final transferContent = 'NAPTIEN_$uid';

    return Scaffold(
      appBar: AppBar(title: Text(t.topUp)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(t.topUpByQr, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Center(
            child: QrImageView(
              data: 'bank://MB/0123456789/CONG TY ABC/$transferContent',
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
          SelectableText(t.transferContent(transferContent)),
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
                        SnackBar(content: Text(t.topUpCreated)),
                      );
                    } finally {
                      if (mounted) setState(() => loading = false);
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(loading ? t.processing : t.transferred),
            ),
          )
        ],
      ),
    );
  }
}
