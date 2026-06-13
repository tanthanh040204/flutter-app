/*
 * @file       onboarding_screen.dart
 * @brief      Three-page onboarding carousel shown before login.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/mobile_auth_provider.dart';
import '../widgets/language_switch.dart';

/* Constants ---------------------------------------------------------- */
const Duration kPageAnimDuration = Duration(milliseconds: 250);
const Duration kDotAnimDuration = Duration(milliseconds: 200);
const Color kOnboardBlue = Color(0xFF2563EB);
const Color kOnboardCyan = Color(0xFF06B6D4);
const Color kOnboardOrange = Color(0xFFF97316);

/* Public classes ----------------------------------------------------- */
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

/* Private classes ---------------------------------------------------- */
class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  List<_OnboardData> _pages(AppStrings t) => [
    _OnboardData(
      title: t.onboardingTitle1,
      desc: t.onboardingDesc1,
      icon: Icons.electric_bike_rounded,
      color: kOnboardBlue,
    ),
    _OnboardData(
      title: t.onboardingTitle2,
      desc: t.onboardingDesc2,
      icon: Icons.qr_code_scanner,
      color: kOnboardOrange,
    ),
    _OnboardData(
      title: t.onboardingTitle3,
      desc: t.onboardingDesc3,
      icon: Icons.pedal_bike_rounded,
      color: kOnboardCyan,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final AppStrings t = context.tr;
    final List<_OnboardData> pages = _pages(t);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: LanguageSwitch(),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) {
                      final _OnboardData page = pages[i];
                      return Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 560),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(34),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 26,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      page.color.withValues(alpha: 0.14),
                                      page.color.withValues(alpha: 0.05),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  page.icon,
                                  size: 96,
                                  color: page.color,
                                ),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                page.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 32,
                                  height: 1.12,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                page.desc,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 17,
                                  height: 1.45,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(pages.length, (i) {
                    final bool active = i == _index;
                    return AnimatedContainer(
                      duration: kDotAnimDuration,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 26 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: active ? kOnboardOrange : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => context
                              .read<MobileAuthProvider>()
                              .finishOnboarding(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(t.login),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () => context
                              .read<MobileAuthProvider>()
                              .finishOnboarding(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(t.register),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
  final Color color;

  const _OnboardData({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
  });
}

/* End of file -------------------------------------------------------- */
