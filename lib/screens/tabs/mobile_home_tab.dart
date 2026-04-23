/*
 * @file       mobile_home_tab.dart
 * @brief      Home tab: greets the user, shows balance and the current ride
 *             card. Reacts to MQTT-driven warnings and end-of-rental events.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/error_codes.dart';
import '../../providers/mobile_auth_provider.dart';
import '../../providers/mobile_ride_provider.dart';
import '../../services/protocol_codec.dart';
import '../bill_screen.dart';
import '../qr_scan_screen.dart';
import '../wallet_topup_screen.dart';

/* Constants ---------------------------------------------------------- */
const Color  kHeaderGradientStart = Color(0xFF1557FF);
const Color  kHeaderGradientEnd   = Color(0xFF2F80ED);
const String kCurrencyLocale      = 'vi_VN';
const String kCurrencySymbol      = 'đ';

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

  @override
  Widget build(BuildContext context) {
    final MobileAuthProvider auth = context.watch<MobileAuthProvider>();
    final MobileRideProvider ride = context.watch<MobileRideProvider>();
    final user = auth.currentUser;

    if (user == null) return const SizedBox.shrink();

    _handleRideSideEffects(ride);

    final NumberFormat money = NumberFormat.currency(
      locale: kCurrencyLocale,
      symbol: kCurrencySymbol,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Trang chủ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(user.fullName, user.employeeCode, user.balance,
              user.depositLocked, money),
          const SizedBox(height: 16),
          _buildQuickActions(),
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

  void _handleRideSideEffects(MobileRideProvider ride) {
    if (ride.isEnded && ride.lastBill != null && !_billShown) {
      _billShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BillScreen(bill: ride.lastBill!),
          ),
        );
      });
    }
    if (!ride.isEnded) _billShown = false;
  }

  Widget _buildHeader(String fullName, String employeeCode, int balance,
      int depositLocked, NumberFormat money) {
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
            'Xin chào, $fullName',
            style: const TextStyle(
              color:      Colors.white,
              fontSize:   24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text('Mã xác nhận: $employeeCode',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _QuickCard(title: 'Số dư',   value: money.format(balance)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickCard(
                  title: 'Tiền cọc',
                  value: money.format(depositLocked),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WalletTopupScreen()),
            ),
            icon:  const Icon(Icons.qr_code_2),
            label: const Text('Nạp tiền'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QrScanScreen()),
            ),
            icon:  const Icon(Icons.qr_code_scanner),
            label: const Text('Quét QR'),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningCard(MobileRideProvider ride) {
    final String w = ride.warning!;
    final bool severe =
        w == kEvtWarnOutOfBalance || w == kErrOutOfParkingZone;
    final String title = switch (w) {
      kEvtWarnLowBalance   => 'Số dư sắp hết',
      kEvtWarnOutOfBalance => 'Hết tiền — cần trả xe tại bãi',
      kErrOutOfParkingZone => 'Xe đang ngoài bãi đỗ hợp lệ',
      _                    => 'Cảnh báo',
    };
    final String body = switch (w) {
      kEvtWarnLowBalance   => 'Bạn chỉ còn đủ cho block hiện tại. Hãy nạp thêm tiền.',
      kEvtWarnOutOfBalance => 'Vui lòng đưa xe về bãi trong 15 phút để tránh bị phạt.',
      kErrOutOfParkingZone => 'Hãy đưa xe đến bãi gần nhất để kết thúc chuyến đi.',
      _                    => '',
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
          title:    Text(title),
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
          leading:  const Icon(Icons.error, color: Colors.red),
          title:    const Text('Không thể bắt đầu chuyến đi'),
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
          color:        Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hiện chưa có chuyến đi nào',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text('Bạn có thể nạp tiền và quét QR trên xe để bắt đầu sử dụng.'),
          ],
        ),
      );
    }

    if (ride.phase == RentalPhase.starting) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            SizedBox(width: 14),
            Text('Đang mở khóa xe...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xe ${ride.currentBikeId ?? ''} — ${ride.isPaused ? 'đang tạm ngưng' : 'đang sử dụng'}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            _formatSeconds(ride.liveRemainingSeconds),
            style: const TextStyle(
              fontSize:   40,
              fontWeight: FontWeight.w900,
              color:      kHeaderGradientStart,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ride.isPaused
                ? 'Giá thuê hiện giảm 50% (${ride.effectivePricePerHour}đ/giờ).'
                : 'Giá thuê: ${ride.pricing.pricePerHour}đ/giờ.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: ride.isPaused ? ride.resumeRide : ride.pauseRide,
                  child: Text(ride.isPaused ? 'Tiếp tục' : 'Tạm ngưng'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: ride.phase == RentalPhase.stopping
                      ? null
                      : ride.endRide,
                  child: Text(ride.phase == RentalPhase.stopping
                      ? 'Đang kết thúc...'
                      : 'Kết thúc'),
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
        color:        Colors.white.withOpacity(0.15),
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
              color:      Colors.white,
              fontWeight: FontWeight.w800,
              fontSize:   18,
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
