/*
 * @file       login_register_screen.dart
 * @brief      Combined login / register screen with email, phone and password.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/mobile_auth_provider.dart';
import '../widgets/language_switch.dart';

/* Constants ---------------------------------------------------------- */
const String kDefaultDemoEmail = 'demo@tngo.vn';
const String kDefaultDemoPhone = '0900000001';
const String kDefaultDemoPassword = '123456';

/* Public classes ----------------------------------------------------- */
class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

/* Private classes ---------------------------------------------------- */
class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  bool loginMode = true;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  final TextEditingController fullNameCtl = TextEditingController(
    text: 'Người dùng UTE-GO',
  );
  final TextEditingController emailCtl = TextEditingController(
    text: kDefaultDemoEmail,
  );
  final TextEditingController phoneCtl = TextEditingController(
    text: kDefaultDemoPhone,
  );
  final TextEditingController passwordCtl = TextEditingController(
    text: kDefaultDemoPassword,
  );
  final TextEditingController confirmPasswordCtl = TextEditingController(
    text: kDefaultDemoPassword,
  );

  @override
  void dispose() {
    fullNameCtl.dispose();
    emailCtl.dispose();
    phoneCtl.dispose();
    passwordCtl.dispose();
    confirmPasswordCtl.dispose();
    super.dispose();
  }

  bool _validate() {
    final AppStrings t = context.readTr;
    final String email = emailCtl.text.trim();
    final String phone = phoneCtl.text.trim();
    final String password = passwordCtl.text.trim();
    final String confirmPassword = confirmPasswordCtl.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.invalidEmail)),
      );
      return false;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.passwordRequired)),
      );
      return false;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.passwordMinLength)),
      );
      return false;
    }

    if (!loginMode && phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.phoneRequired)),
      );
      return false;
    }

    if (!loginMode && confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.confirmPasswordRequired)),
      );
      return false;
    }

    if (!loginMode && password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.passwordMismatch)),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings t = context.tr;
    final MobileAuthProvider auth = context.watch<MobileAuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(loginMode ? t.login : t.register),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: LanguageSwitch(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(t.login)),
                ButtonSegment(value: false, label: Text(t.register)),
              ],
              selected: {loginMode},
              onSelectionChanged: (value) =>
                  setState(() => loginMode = value.first),
            ),
            const SizedBox(height: 20),

            if (!loginMode) ...[
              TextField(
                controller: fullNameCtl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: t.fullName,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: emailCtl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: passwordCtl,
              obscureText: obscurePassword,
              textInputAction: loginMode
                  ? TextInputAction.done
                  : TextInputAction.next,
              decoration: InputDecoration(
                labelText: t.password,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: obscurePassword ? t.showPassword : t.hidePassword,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => obscurePassword = !obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (!loginMode) ...[
              TextField(
                controller: confirmPasswordCtl,
                obscureText: obscureConfirmPassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: t.confirmPassword,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  suffixIcon: IconButton(
                    tooltip: obscureConfirmPassword
                        ? t.showPassword
                        : t.hidePassword,
                    icon: Icon(
                      obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(
                      () => obscureConfirmPassword = !obscureConfirmPassword,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: t.phoneNumber,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (auth.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  auth.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            FilledButton(
              onPressed: auth.loading
                  ? null
                  : () async {
                      if (!_validate()) return;

                      final bool ok = loginMode
                          ? await auth.login(
                              identifier: emailCtl.text.trim(),
                              password: passwordCtl.text.trim(),
                              usePhone: false,
                            )
                          : await auth.register(
                              fullName: fullNameCtl.text.trim().isEmpty
                                  ? t.demoUserName
                                  : fullNameCtl.text.trim(),
                              employeeCode: '',
                              identifier: emailCtl.text.trim(),
                              phone: phoneCtl.text.trim(),
                              password: passwordCtl.text.trim(),
                              usePhone: false,
                            );

                      if (!mounted || !ok) return;
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: auth.loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        loginMode ? t.login : t.createAccount,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loginMode ? t.loginHint : t.registerHint,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

/* End of file -------------------------------------------------------- */
