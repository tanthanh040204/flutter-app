import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/mobile_auth_provider.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  bool loginMode = true;
  bool usePhone = false;
  final fullNameCtl = TextEditingController();
  final employeeCtl = TextEditingController();
  final identifierCtl = TextEditingController(text: 'demo@tngo.vn');
  final passwordCtl = TextEditingController(text: '123456');

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
    final auth = context.watch<MobileAuthProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(loginMode ? 'Đăng nhập' : 'Đăng ký')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Đăng nhập')),
                ButtonSegment(value: false, label: Text('Đăng ký')),
              ],
              selected: {loginMode},
              onSelectionChanged: (v) => setState(() => loginMode = v.first),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Email')),
                ButtonSegment(value: true, label: Text('Số điện thoại')),
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
                decoration: const InputDecoration(labelText: 'Họ và tên'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: employeeCtl,
                decoration: const InputDecoration(labelText: 'Mã Xác Nhận'),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: identifierCtl,
              keyboardType: usePhone
                  ? TextInputType.phone
                  : TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: usePhone ? 'Số điện thoại' : 'Email',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordCtl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
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
                      final ok = loginMode
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
                        loginMode ? 'Đăng nhập' : 'Tạo tài khoản',
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
                'Bản MVP: chế độ số điện thoại đang chạy theo demo để bạn test nhanh trong VS Code. Muốn chạy OTP thật cần cấu hình Firebase Phone Auth.',
                style: TextStyle(color: Colors.black54),
              ),
            if (!usePhone)
              const Text(
                'Chào mừng bạn đến với UTE-GO',
                style: TextStyle(color: Colors.black54),
              ),
          ],
        ),
      ),
    );
  }
}
