/*
 * @file       mobile_home_tab.dart
 * @brief      Home tab: greets the user, shows balance and current ride card.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/mobile_auth_provider.dart';
import '../../providers/mobile_ride_provider.dart';
import '../qr_scan_screen.dart';
import '../wallet_topup_screen.dart';

/* Constants ---------------------------------------------------------- */
const Color kHeaderGradientStart = Color(0xFF1557FF);
const Color kHeaderGradientEnd = Color(0xFF2F80ED);
const String kCurrencyLocale = 'vi_VN';
const String kCurrencySymbol = 'đ';

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class MobileHomeTab extends StatelessWidget {
  const MobileHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final MobileAuthProvider auth = context.watch<MobileAuthProvider>();
    final MobileRideProvider ride = context.watch<MobileRideProvider>();
    final user = auth.currentUser;

    if (user == null) return const SizedBox.shrink();

    final NumberFormat money = NumberFormat.currency(
      locale: kCurrencyLocale,
      symbol: kCurrencySymbol,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Trang chủ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
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
                  'Xin chào, ${user.fullName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mã xác nhận: ${user.employeeCode}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _QuickCard(
                        title: 'Số dư',
                        value: money.format(user.balance),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickCard(
                        title: 'Tiền cọc',
                        value: money.format(user.depositLocked),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WalletTopupScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('Nạp tiền'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QrScanScreen()),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Quét QR'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (ride.session == null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  Text(
                    'Bạn có thể nạp tiền và quét QR trên xe để bắt đầu sử dụng.',
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${ride.session!.vehicleName} đang được sử dụng',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
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
                  const Text(
                    'Thời gian còn lại ước tính theo số tiền hiện tại.',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: ride.session!.isPaused
                              ? ride.resumeRide
                              : ride.pauseRide,
                          child: Text(
                            ride.session!.isPaused ? 'Tiếp tục' : 'Tạm ngưng',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: ride.endRide,
                          child: const Text('Kết thúc'),
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

  String _formatSeconds(int seconds) {
    final String h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final String m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final String s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

/* Private classes ---------------------------------------------------- */
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
