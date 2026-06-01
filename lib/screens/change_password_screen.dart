/*
 * @file       change_password_screen.dart
 * @brief      Screen for the user to change their account password.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/mobile_auth_provider.dart';

/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

/* Private classes ---------------------------------------------------- */
class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController currentCtl = TextEditingController();
  final TextEditingController newCtl = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    currentCtl.dispose();
    newCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings t = context.tr;
    return Scaffold(
      appBar: AppBar(title: Text(t.changePassword)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: currentCtl,
            obscureText: true,
            decoration: InputDecoration(labelText: t.currentPassword),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newCtl,
            obscureText: true,
            decoration: InputDecoration(labelText: t.newPassword),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: loading
                ? null
                : () async {
                    setState(() => loading = true);
                    final ScaffoldMessengerState messenger =
                        ScaffoldMessenger.of(context);
                    final NavigatorState navigator = Navigator.of(context);
                    final MobileAuthProvider auth = context
                        .read<MobileAuthProvider>();
                    try {
                      await auth.changePassword(
                        currentPassword: currentCtl.text,
                        newPassword: newCtl.text,
                      );
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text(t.passwordChanged)),
                      );
                      navigator.pop();
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    } finally {
                      if (mounted) setState(() => loading = false);
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(loading ? t.saving : t.saveNewPassword),
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
