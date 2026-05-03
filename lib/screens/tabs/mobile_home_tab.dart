import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../providers/mobile_auth_provider.dart';
import '../../providers/mobile_ride_provider.dart';
import '../../widgets/extend_ride_sheet.dart';
import '../qr_scan_screen.dart';
import '../wallet_topup_screen.dart';

class MobileHomeTab extends StatefulWidget {
  const MobileHomeTab({super.key});

  @override
  State<MobileHomeTab> createState() => _MobileHomeTabState();
}

class _MobileHomeTabState extends State<MobileHomeTab> {
  late final TextEditingController _hoursCtrl;

  @override
  void initState() {
    super.initState();
    _hoursCtrl = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _hoursCtrl.dispose();
    super.dispose();
  }

  void _applyHours(BuildContext context) {
    final ride = context.read<MobileRideProvider>();
    final text = _hoursCtrl.text.trim();
    final hours = int.tryParse(text);

    if (hours == null || hours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.readTr.invalidHours)),
      );
      return;
    }

    ride.setSelectedRentalHours(hours);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tr;
    final auth = context.watch<MobileAuthProvider>();
    final ride = context.watch<MobileRideProvider>();
    final user = auth.currentUser;

    if (user == null) return const SizedBox.shrink();

    final money = NumberFormat.currency(locale: t.moneyLocale, symbol: t.moneySymbol);

    return Scaffold(
      appBar: AppBar(title: Text(t.home)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1557FF), Color(0xFF2F80ED)]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.hello(user.fullName),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(user.email ?? user.phone ?? '', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _QuickCard(title: t.balance, value: money.format(user.balance))),
                    const SizedBox(width: 12),
                    Expanded(child: _QuickCard(title: t.deposit, value: money.format(user.depositLocked))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (ride.session == null) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.enterRentalTime, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _hoursCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: t.rentalHoursLabel,
                      hintText: t.hourHint,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.timer_outlined),
                    ),
                    onChanged: (_) => _applyHours(context),
                    onSubmitted: (_) => _applyHours(context),
                  ),
                  const SizedBox(height: 14),
                  Text(t.selectedRentalHours(ride.selectedRentalHours), style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(t.rentalFee(money.format(ride.selectedUsageFee)), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(t.depositFee(money.format(ride.pricing.depositAmount)), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    t.requiredTotal(money.format(ride.selectedTotalRequired)),
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1557FF)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletTopupScreen()));
                  },
                  icon: const Icon(Icons.qr_code_2),
                  label: Text(t.topUp),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    _applyHours(context);
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QrScanScreen()));
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(t.scanQr),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (ride.session == null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.noRideTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(t.noRideDesc),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.vehicleInUse(ride.session!.vehicleName),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  if (ride.showExtendPrompt) ...[
                    _ExtendWarningCard(onTap: () => showExtendRideSheet(context)),
                    const SizedBox(height: 12),
                  ],
                  if (ride.showReturnPrompt) ...[
                    const _ReturnWarningCard(),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    _formatSeconds(ride.liveRemainingSeconds),
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF1557FF)),
                  ),
                  const SizedBox(height: 6),
                  Text(t.remainingTimeDesc),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: ride.session!.isPaused ? ride.resumeRide : ride.pauseRide,
                          child: Text(ride.session!.isPaused ? t.resume : t.pause),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: ride.endRide,
                          child: Text(t.end),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _formatSeconds(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _ExtendWarningCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ExtendWarningCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.tr;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6D8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7C76C)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_filled, color: Color(0xFF9A6700)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(t.extendWarning, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReturnWarningCard extends StatelessWidget {
  const _ReturnWarningCard();

  @override
  Widget build(BuildContext context) {
    final t = context.tr;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB4B4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB42318)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.returnStationWarning,
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFB42318)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String title;
  final String value;

  const _QuickCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
