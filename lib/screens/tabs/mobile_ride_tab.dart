/*
 * @file       mobile_ride_tab.dart
 * @brief      Ride tab: shows the current rental state and its controls.
 *             Vehicle telemetry will arrive via bike_id/data once wired.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/error_codes.dart';
import '../../providers/mobile_ride_provider.dart';
import '../../services/protocol_codec.dart';

/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class MobileRideTab extends StatelessWidget {
  const MobileRideTab({super.key});

  @override
  Widget build(BuildContext context) {
    final MobileRideProvider ride = context.watch<MobileRideProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Thông số')),
      body: !ride.hasActiveSession
          ? const Center(
              child: Text(
                'Bạn chưa sử dụng xe',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            )
          : _buildContent(context, ride),
    );
  }

  Widget _buildContent(BuildContext context, MobileRideProvider ride) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (ride.warning != null) _buildWarning(ride),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xe ${ride.currentBikeId ?? ''}',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                _InfoRow(
                  label: 'Trạng thái',
                  value: ride.isPaused ? 'Đang tạm ngưng' : 'Đang sử dụng',
                ),
                _InfoRow(
                  label: 'Giá hiện tại',
                  value: '${ride.effectivePricePerHour}đ/giờ'
                      '${ride.isPaused ? ' (giảm 50%)' : ''}',
                ),
                _InfoRow(
                  label: 'Thời gian đã dùng',
                  value: _formatSeconds(ride.liveRemainingSeconds),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.tonal(
          onPressed: ride.isPaused ? ride.resumeRide : ride.pauseRide,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              ride.isPaused ? 'Tiếp tục sử dụng' : 'Tạm ngưng sử dụng',
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: ride.phase == RentalPhase.stopping ? null : ride.endRide,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              ride.phase == RentalPhase.stopping
                  ? 'Đang kết thúc...'
                  : 'Ngưng sử dụng',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarning(MobileRideProvider ride) {
    final String w       = ride.warning!;
    final bool   severe  =
        w == kEvtWarnOutOfBalance || w == kErrOutOfParkingZone;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: severe ? Colors.red.shade50 : Colors.orange.shade50,
        child: ListTile(
          leading: Icon(
            severe ? Icons.error : Icons.warning_amber,
            color: severe ? Colors.red : Colors.orange,
          ),
          title:    Text(_titleFor(w)),
          subtitle: Text(_bodyFor(w)),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: ride.clearWarning,
          ),
        ),
      ),
    );
  }

  String _titleFor(String code) {
    switch (code) {
      case kEvtWarnLowBalance:   return 'Số dư sắp hết';
      case kEvtWarnOutOfBalance: return 'Hết tiền — cần trả xe';
      case kErrOutOfParkingZone: return 'Xe ngoài bãi đỗ';
      default:                   return 'Cảnh báo';
    }
  }

  String _bodyFor(String code) {
    switch (code) {
      case kEvtWarnLowBalance:
        return 'Bạn chỉ còn đủ cho block hiện tại. Hãy nạp thêm tiền.';
      case kEvtWarnOutOfBalance:
        return 'Vui lòng đưa xe về bãi trong 15 phút để tránh bị phạt.';
      case kErrOutOfParkingZone:
        return 'Hãy đưa xe đến bãi gần nhất để kết thúc chuyến đi.';
      default:
        return '';
    }
  }

  String _formatSeconds(int seconds) {
    final String h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final String m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final String s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

/* Private classes ---------------------------------------------------- */
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
