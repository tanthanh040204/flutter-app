/*
 * @file       mobile_home_tab.dart
 * @brief      Home tab: greets the user, shows balance and the current ride
 *             card. Reacts to MQTT-driven warnings and end-of-rental events.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/error_codes.dart';
import '../../providers/mobile_auth_provider.dart';
import '../../providers/mobile_ride_provider.dart';
import '../../services/protocol_codec.dart';
import '../bill_screen.dart';
import '../qr_scan_screen.dart';
import '../wallet_topup_screen.dart';
import '../../widgets/language_switch.dart';

/* Constants ---------------------------------------------------------- */
const Color kHeaderGradientStart = Color(0xFF1557FF);
const Color kHeaderGradientEnd = Color(0xFF2F80ED);
const String kCurrencyLocale = 'vi_VN';
const String kCurrencySymbol = 'đ';

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class MobileHomeTab extends StatefulWidget {
  const MobileHomeTab({super.key});

  @override
  State<MobileHomeTab> createState() => _MobileHomeTabState();
}

/* Private classes ---------------------------------------------------- */
class _MobileHomeTabState extends State<MobileHomeTab> {
  bool _billShown = false;
  DateTime? _lastDeductedBillAt;
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

  bool _applyHours(BuildContext context) {
    final MobileRideProvider ride = context.read<MobileRideProvider>();
    final int? hours = int.tryParse(_hoursCtrl.text.trim());

    if (hours == null || hours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.readTr.invalidHours)),
      );
      return false;
    }

    ride.setSelectedRentalHours(hours);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings t = context.tr;
    final MobileAuthProvider auth = context.watch<MobileAuthProvider>();
    final MobileRideProvider ride = context.watch<MobileRideProvider>();
    final user = auth.currentUser;

    if (user == null) return const SizedBox.shrink();

    _handleRideSideEffects(auth, ride);

    final NumberFormat money = NumberFormat.currency(
      locale: t.moneyLocale,
      symbol: t.moneySymbol,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.home),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: LanguageSwitch(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(
            user.fullName,
            user.email ?? user.phone ?? user.employeeCode,
            user.balance,
            user.depositLocked,
            money,
          ),
          const SizedBox(height: 16),
          if (!ride.hasActiveSession && ride.phase != RentalPhase.starting) ...[
            _buildRentalTimeCard(ride, money, t),
            const SizedBox(height: 16),
          ],
          _buildQuickActions(t),
          const SizedBox(height: 20),
          if (ride.warning != null) _buildWarningCard(ride),
          if (ride.lastError != null && !ride.hasActiveSession)
            _buildErrorCard(ride),
          const SizedBox(height: 12),
          _buildRideCard(ride),
        ],
      ),
    );
  }

  void _handleRideSideEffects(
    MobileAuthProvider auth,
    MobileRideProvider ride,
  ) {
    if (ride.isEnded && ride.lastBill != null && !_billShown) {
      if (_lastDeductedBillAt != ride.lastBill!.endedAt) {
        auth.deductLocalBalance(ride.lastBill!.amount);
        _lastDeductedBillAt = ride.lastBill!.endedAt;
      }
      _billShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BillScreen(bill: ride.lastBill!)),
        );
      });
    }
    if (!ride.isEnded) _billShown = false;
  }

  Widget _buildHeader(
    String fullName,
    String userCode,
    int balance,
    int depositLocked,
    NumberFormat money,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kHeaderGradientStart, kHeaderGradientEnd],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr.hello(fullName),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            userCode,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _QuickCard(
                  title: context.tr.balance,
                  value: money.format(balance),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickCard(
                  title: context.tr.deposit,
                  value: money.format(depositLocked),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRentalTimeCard(
    MobileRideProvider ride,
    NumberFormat money,
    AppStrings t,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.enterRentalTime,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
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
          Text(
            t.selectedRentalHours(ride.selectedRentalHours),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            t.rentalFee(money.format(ride.selectedUsageFee)),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            t.depositFee(money.format(ride.pricing.depositAmount)),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            t.requiredTotal(money.format(ride.selectedTotalRequired)),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: kHeaderGradientStart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(AppStrings t) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WalletTopupScreen()),
            ),
            icon: const Icon(Icons.qr_code_2),
            label: Text(t.topUp),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () {
              if (!_applyHours(context)) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QrScanScreen()),
              );
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(t.scanQr),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningCard(MobileRideProvider ride) {
    final String w = ride.warning!;
    final bool severe = w == kEvtWarnOutOfBalance || w == kErrOutOfParkingZone;
    final String title = switch (w) {
      kEvtWarnLowBalance => 'Balance running low',
      kEvtWarnOutOfBalance => 'Out of balance — please return the bike',
      kErrOutOfParkingZone => 'Vehicle is outside a valid parking zone',
      _ => 'Warning',
    };
    final String body = switch (w) {
      kEvtWarnLowBalance =>
        'You only have enough for the current block. Please top up.',
      kEvtWarnOutOfBalance =>
        'Return the bike to a parking zone within 15 minutes to avoid '
            'a penalty.',
      kErrOutOfParkingZone =>
        'Move the bike to the nearest parking zone to end the ride.',
      _ => '',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: severe ? Colors.red.shade50 : Colors.orange.shade50,
        child: ListTile(
          leading: Icon(
            severe ? Icons.error : Icons.warning_amber,
            color: severe ? Colors.red : Colors.orange,
          ),
          title: Text(title),
          subtitle: Text(body),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: ride.clearWarning,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(MobileRideProvider ride) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: Colors.red.shade50,
        child: ListTile(
          leading: const Icon(Icons.error, color: Colors.red),
          title: const Text('Could not start the ride'),
          subtitle: Text(ErrorMessages.describe(ride.lastError!)),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: ride.clearError,
          ),
        ),
      ),
    );
  }

  Widget _buildRideCard(MobileRideProvider ride) {
    if (!ride.hasActiveSession && ride.phase != RentalPhase.starting) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr.noRideTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(context.tr.noRideDesc),
          ],
        ),
      );
    }

    if (ride.phase == RentalPhase.starting) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            SizedBox(width: 14),
            Text('Unlocking the bike...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ride.isPaused
                ? 'Bike ${ride.currentBikeId ?? ''} — ${context.tr.pause}'
                : context.tr.vehicleInUse('Bike ${ride.currentBikeId ?? ''}'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            _formatSeconds(ride.liveRemainingSeconds),
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: kHeaderGradientStart,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ride.isPaused
                ? '${context.tr.pause}: ${ride.effectivePricePerHour}đ/hour.'
                : '${context.tr.pricePerHour}: ${ride.pricing.pricePerHour}đ/hour.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: ride.isPaused ? ride.resumeRide : ride.pauseRide,
                  child: Text(
                    ride.isPaused ? context.tr.resume : context.tr.pause,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: ride.phase == RentalPhase.stopping
                      ? null
                      : ride.endRide,
                  child: Text(
                    ride.phase == RentalPhase.stopping
                        ? context.tr.processing
                        : context.tr.end,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSeconds(int seconds) {
    final String h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final String m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final String s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
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
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
