/*
 * @file       login_register_screen.dart
 * @brief      Combined login / register screen with email or phone modes.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/mobile_auth_provider.dart';

/* Constants ---------------------------------------------------------- */
const String kDefaultDemoIdentifier = 'demo@tngo.vn';
const String kDefaultDemoPassword = '123456';

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

/* Private classes ---------------------------------------------------- */
class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  bool loginMode = true;
  bool usePhone = false;
  final TextEditingController fullNameCtl = TextEditingController();
  final TextEditingController employeeCtl = TextEditingController();
  final TextEditingController identifierCtl = TextEditingController(
    text: kDefaultDemoIdentifier,
  );
  final TextEditingController passwordCtl = TextEditingController(
    text: kDefaultDemoPassword,
  );

  @override
  void dispose() {
    fullNameCtl.dispose();
    employeeCtl.dispose();
    identifierCtl.dispose();
    passwordCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MobileAuthProvider auth = context.watch<MobileAuthProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(loginMode ? 'Sign in' : 'Register')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Sign in')),
                ButtonSegment(value: false, label: Text('Register')),
              ],
              selected: {loginMode},
              onSelectionChanged: (v) => setState(() => loginMode = v.first),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Email')),
                ButtonSegment(value: true, label: Text('Phone')),
              ],
              selected: {usePhone},
              onSelectionChanged: (v) {
                setState(() {
                  usePhone = v.first;
                });
              },
            ),
            const SizedBox(height: 20),
            if (!loginMode) ...[
              TextField(
                controller: fullNameCtl,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: employeeCtl,
                decoration: const InputDecoration(labelText: 'Employee code'),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: identifierCtl,
              keyboardType: usePhone
                  ? TextInputType.phone
                  : TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: usePhone ? 'Phone number' : 'Email',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordCtl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
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
                      final bool ok = loginMode
                          ? await auth.login(
                              identifier: identifierCtl.text,
                              password: passwordCtl.text,
                              usePhone: usePhone,
                            )
                          : await auth.register(
                              fullName: fullNameCtl.text,
                              employeeCode: employeeCtl.text,
                              identifier: identifierCtl.text,
                              password: passwordCtl.text,
                              usePhone: usePhone,
                            );
                      if (!mounted || !ok) return;
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: auth.loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        loginMode ? 'Sign in' : 'Create account',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            if (usePhone)
              const Text(
                'MVP build: phone mode runs in demo only so you can test '
                'quickly in VS Code. Real OTP requires Firebase Phone Auth '
                'to be configured.',
                style: TextStyle(color: Colors.black54),
              ),
            if (!usePhone)
              const Text(
                'Welcome to UTE-GO',
                style: TextStyle(color: Colors.black54),
              ),
          ],
        ),
      ),
    );
  }
}

/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
