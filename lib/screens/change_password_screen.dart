import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/mobile_auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final currentCtl = TextEditingController();
  final newCtl = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    currentCtl.dispose();
    newCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tr;

    return Scaffold(
      appBar: AppBar(title: Text(t.changePassword)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: currentCtl, obscureText: true, decoration: InputDecoration(labelText: t.currentPassword)),
          const SizedBox(height: 12),
          TextField(controller: newCtl, obscureText: true, decoration: InputDecoration(labelText: t.newPassword)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: loading
                ? null
                : () async {
                    setState(() => loading = true);
                    try {
                      await context.read<MobileAuthProvider>().changePassword(
                            currentPassword: currentCtl.text,
                            newPassword: newCtl.text,
                          );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.passwordChanged)),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    } finally {
                      if (mounted) setState(() => loading = false);
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(loading ? t.processing : t.saveNewPassword),
            ),
          ),
        ],
      ),
    );
  }
}
