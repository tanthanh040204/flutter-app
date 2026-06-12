/*
 * @file       mobile_more_tab.dart
 * @brief      "More" tab: profile card, language switcher, password, pricing
 *             and logout.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../providers/app_language_provider.dart';
import '../../providers/mobile_auth_provider.dart';
import '../change_password_screen.dart';
import '../pricing_screen.dart';
import '../usage_guide_screen.dart';

/* Constants ---------------------------------------------------------- */
const Color kHeaderGradientStart = Color(0xFF2563EB);
const Color kHeaderGradientEnd = Color(0xFF06B6D4);
const Color kMoreViolet = Color(0xFF7C3AED);
const Color kMoreOrange = Color(0xFFF97316);
const Color kMoreGreen = Color(0xFF16A34A);

/* Public classes ----------------------------------------------------- */
class MobileMoreTab extends StatelessWidget {
  const MobileMoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStrings t = context.tr;
    final AppLanguageProvider languageProvider =
        context.watch<AppLanguageProvider>();
    final MobileAuthProvider auth = context.watch<MobileAuthProvider>();
    final user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: Text(t.more)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC), Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kHeaderGradientStart, kHeaderGradientEnd],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: kHeaderGradientStart.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    child: const Icon(Icons.person, size: 38, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          user.email ?? user.phone ?? user.employeeCode,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: kHeaderGradientStart.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.language, color: kHeaderGradientStart),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.language,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              t.languageSubtitle,
                              style: const TextStyle(color: Colors.black54, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<AppLanguage>(
                      segments: [
                        ButtonSegment(
                          value: AppLanguage.vi,
                          label: Text(t.vietnamese),
                        ),
                        ButtonSegment(
                          value: AppLanguage.en,
                          label: Text(t.english),
                        ),
                      ],
                      selected: {languageProvider.language},
                      onSelectionChanged: (value) => context
                          .read<AppLanguageProvider>()
                          .setLanguage(value.first),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _MenuTile(
              icon: Icons.lock_reset,
              color: kMoreViolet,
              title: t.changePassword,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.price_change,
              color: kMoreOrange,
              title: t.priceList,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PricingScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.menu_book_outlined,
              color: kMoreGreen,
              title: t.usageGuideTitle,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UsageGuideScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.logout,
              color: Colors.red,
              title: t.logout,
              onTap: () => context.read<MobileAuthProvider>().logout(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

/* End of file -------------------------------------------------------- */
