/*
 * @file       usage_guide_screen.dart
 * @brief      Simple in-app guide for new riders.
 */

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

const Color kGuideBlue = Color(0xFF1557FF);
const Color kGuideCyan = Color(0xFF2F80ED);

class UsageGuideScreen extends StatelessWidget {
  const UsageGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStrings t = context.tr;
    final List<_GuideStep> steps = <_GuideStep>[
      _GuideStep(
        icon: Icons.login,
        title: t.guideStepLoginTitle,
        body: t.guideStepLoginBody,
      ),
      _GuideStep(
        icon: Icons.account_balance_wallet_outlined,
        title: t.guideStepTopUpTitle,
        body: t.guideStepTopUpBody,
      ),
      _GuideStep(
        icon: Icons.timer_outlined,
        title: t.guideStepTimeTitle,
        body: t.guideStepTimeBody,
      ),
      _GuideStep(
        icon: Icons.qr_code_scanner,
        title: t.guideStepQrTitle,
        body: t.guideStepQrBody,
      ),
      _GuideStep(
        icon: Icons.directions_bike,
        title: t.guideStepRideTitle,
        body: t.guideStepRideBody,
      ),
      _GuideStep(
        icon: Icons.assignment_turned_in_outlined,
        title: t.guideStepReturnTitle,
        body: t.guideStepReturnBody,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(t.usageGuideTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kGuideBlue, kGuideCyan]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.route, color: Colors.white, size: 42),
                const SizedBox(height: 14),
                Text(
                  t.usageGuideTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.usageGuideIntro,
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < steps.length; i++) ...[
            _GuideStepTile(index: i + 1, step: steps[i]),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates, color: Color(0xFFF57C00)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.usageGuideTip,
                    style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35),
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

class _GuideStepTile extends StatelessWidget {
  final int index;
  final _GuideStep step;

  const _GuideStepTile({required this.index, required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: kGuideBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(step.icon, color: kGuideBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. ${step.title}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  step.body,
                  style: const TextStyle(color: Colors.black54, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStep {
  final IconData icon;
  final String title;
  final String body;

  const _GuideStep({required this.icon, required this.title, required this.body});
}
