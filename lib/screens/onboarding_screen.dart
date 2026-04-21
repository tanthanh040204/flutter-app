import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/mobile_auth_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _pages = const [
    _OnboardData(
      title: 'Xe đạp công cộng - Đi bất kỳ đâu',
      desc:
          'Bạn có thể lấy xe tại một trạm, thực hiện chuyến đi và trả xe tại một trạm bất kỳ.',
      icon: Icons.car_rental_rounded,
    ),
    _OnboardData(
      title: 'Quét QR để mở khóa',
      desc:
          'Chỉ cần quét QR trên xe và xác nhận sử dụng nếu số dư của bạn hợp lệ.',
      icon: Icons.qr_code_scanner,
    ),
    _OnboardData(
      title: 'Kết thúc chuyến đi',
      desc:
          'Đỗ xe tại trạm, khóa xe và xác nhận trả xe trên ứng dụng di động để kết thúc chuyến đi.',
      icon: Icons.directions_car,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) {
                    final page = _pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 88,
                          backgroundColor: Colors.blue.shade50,
                          child: Icon(page.icon, size: 110, color: Colors.blue),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.desc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 20 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: active ? Colors.orange : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _index == 0
                          ? null
                          : () => _controller.previousPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            ),
                      child: const Text('Trước đó'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: _index == _pages.length - 1
                          ? null
                          : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            ),
                      child: const Text('Tiếp theo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      context.read<MobileAuthProvider>().finishOnboarding(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () =>
                      context.read<MobileAuthProvider>().finishOnboarding(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Đăng ký',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardData {
  final String title;
  final String desc;
  final IconData icon;

  const _OnboardData({
    required this.title,
    required this.desc,
    required this.icon,
  });
}
