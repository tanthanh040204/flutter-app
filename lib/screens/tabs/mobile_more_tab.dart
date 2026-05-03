import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../providers/app_language_provider.dart';
import '../../providers/mobile_auth_provider.dart';
import '../pricing_screen.dart';

class MobileMoreTab extends StatelessWidget {
  const MobileMoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tr;
    final languageProvider = context.watch<AppLanguageProvider>();
    final auth = context.watch<MobileAuthProvider>();
    final user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: Text(t.more)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1557FF), Color(0xFF2F80ED)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 34,
                  child: Icon(Icons.person, size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? user.phone ?? '',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (!user.isActive) ...[
                        const SizedBox(height: 6),
                        Text(
                          t.accountLocked,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language, color: Color(0xFF1557FF)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.language,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.languageSubtitle,
                              style: const TextStyle(color: Colors.black54),
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
          ),
          const SizedBox(height: 6),
          ListTile(
            leading: const Icon(Icons.price_change),
            title: Text(t.priceList),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PricingScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(t.logout),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.read<MobileAuthProvider>().logout(),
          ),
        ],
      ),
    );
  }
}
