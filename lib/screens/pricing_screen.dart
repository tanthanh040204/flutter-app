/*
 * @file       pricing_screen.dart
 * @brief      Displays current pricing and limits to the end-user.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/pricing_config.dart';
import '../providers/mobile_ride_provider.dart';

/* Constants ---------------------------------------------------------- */
const Color kPricingBlue = Color(0xFF2563EB);
const Color kPricingCyan = Color(0xFF06B6D4);
const Color kPricingOrange = Color(0xFFF97316);
const Color kPricingGreen = Color(0xFF16A34A);

/* Public classes ----------------------------------------------------- */
class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStrings t = context.tr;
    final PricingConfig pricing = context.watch<MobileRideProvider>().pricing;

    return Scaffold(
      appBar: AppBar(title: Text(t.priceList)),
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
                  colors: [kPricingBlue, kPricingCyan],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: kPricingBlue.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.price_change_outlined, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.priceList,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.requiredTotal('${pricing.minimumRequiredBalance}${t.moneySymbol}'),
                          style: const TextStyle(color: Colors.white70, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _PricingTile(
              icon: Icons.schedule,
              title: t.ratePerHour,
              value: '${pricing.pricePerHour}${t.moneySymbol}',
              color: kPricingBlue,
            ),
            const SizedBox(height: 12),
            _PricingTile(
              icon: Icons.lock_outline,
              title: t.deposit,
              value: '${pricing.depositAmount}${t.moneySymbol}',
              color: kPricingOrange,
            ),
            const SizedBox(height: 12),
            _PricingTile(
              icon: Icons.account_balance_wallet_outlined,
              title: t.minimumBalance,
              value: '${pricing.minimumRequiredBalance}${t.moneySymbol}',
              color: kPricingGreen,
            ),
            const SizedBox(height: 12),
            _PricingTile(
              icon: Icons.battery_charging_full,
              title: t.suggestedReturnBatteryThreshold,
              value: '${pricing.lowBatteryThreshold}%',
              color: kPricingCyan,
            ),
          ],
        ),
      ),
    );
  }
}

class _PricingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _PricingTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
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
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/* End of file -------------------------------------------------------- */
