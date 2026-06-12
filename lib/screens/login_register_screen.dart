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
const Color kLoginBlue = Color(0xFF2563EB);
const Color kLoginDarkBlue = Color(0xFF1D4ED8);
const Color kLoginCyan = Color(0xFF06B6D4);

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC), Colors.white],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    children: [
                      _LoginHero(loginMode: loginMode, title: loginMode ? t.login : t.createAccount),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            const SizedBox(height: 18),
                            if (!loginMode) ...[
                              TextField(
                                controller: fullNameCtl,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: t.fullName,
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
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: obscurePassword ? t.showPassword : t.hidePassword,
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => obscurePassword = !obscurePassword,
                                  ),
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
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (auth.error != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.red.shade100),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        auth.error!,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            FilledButton.icon(
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
                              icon: auth.loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(loginMode ? Icons.login : Icons.person_add_alt_1),
                              label: Text(loginMode ? t.login : t.createAccount),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                loginMode ? t.loginHint : t.registerHint,
                                style: const TextStyle(color: Colors.black54, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  final bool loginMode;
  final String title;

  const _LoginHero({required this.loginMode, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kLoginBlue, kLoginDarkBlue, kLoginCyan],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: kLoginBlue.withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              loginMode ? Icons.electric_bike : Icons.verified_user_outlined,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'UTE-GO',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* End of file -------------------------------------------------------- */
