/*
 * @file       mobile_ride_tab.dart
 * @brief      Ride telemetry tab: shows live vehicle data and ride controls.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/mobile_ride_provider.dart';

/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class MobileRideTab extends StatelessWidget {
  const MobileRideTab({super.key});

  @override
  Widget build(BuildContext context) {
    final MobileRideProvider ride = context.watch<MobileRideProvider>();
    final session = ride.session;
    final vehicle = ride.vehicle;

    return Scaffold(
      appBar: AppBar(title: const Text('Thông số')),
      body: session == null || vehicle == null
          ? const Center(
              child: Text(
                'Bạn chưa sử dụng xe',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _InfoRow(
                          label: 'Pin',
                          value: '${vehicle.batteryPercent}%',
                        ),
                        _InfoRow(
                          label: 'Nhiệt độ',
                          value: '${vehicle.temp.toStringAsFixed(1)}°C',
                        ),
                        _InfoRow(
                          label: 'Độ ẩm',
                          value: '${vehicle.hum.toStringAsFixed(1)}%',
                        ),
                        _InfoRow(
                          label: 'Bụi',
                          value: vehicle.dust.toStringAsFixed(1),
                        ),
                        _InfoRow(
                          label: 'Trạng thái',
                          value: session.isPaused
                              ? 'Đang tạm ngưng'
                              : 'Đang sử dụng',
                        ),
                        _InfoRow(
                          label: 'Thời gian còn lại',
                          value: _formatSeconds(ride.liveRemainingSeconds),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: session.isPaused
                      ? ride.resumeRide
                      : ride.pauseRide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      session.isPaused
                          ? 'Tiếp tục sử dụng'
                          : 'Tạm ngưng sử dụng',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: ride.endRide,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Ngưng sử dụng'),
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
