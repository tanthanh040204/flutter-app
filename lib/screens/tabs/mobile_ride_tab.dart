import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../providers/mobile_ride_provider.dart';
import '../../widgets/extend_ride_sheet.dart';

class MobileRideTab extends StatelessWidget {
  const MobileRideTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tr;
    final ride = context.watch<MobileRideProvider>();
    final session = ride.session;
    final vehicle = ride.vehicle;

    return Scaffold(
      appBar: AppBar(title: Text(t.rideStats)),
      body: session == null || vehicle == null
          ? Center(
              child: Text(
                t.notUsingBike,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (ride.showExtendPrompt) ...[
                  _ExtendWarningCard(onTap: () => showExtendRideSheet(context)),
                  const SizedBox(height: 12),
                ],
                if (ride.showReturnPrompt) ...[
                  const _ReturnWarningCard(),
                  const SizedBox(height: 12),
                ],
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
                        if (vehicle.batteryPercent == 0 &&
                            vehicle.temp == 0 &&
                            vehicle.hum == 0 &&
                            vehicle.dust == 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              vehicle.isLocked
                                  ? t.bikeLockedWaitingData
                                  : t.bikeUnlockedWaitingData,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                        _InfoRow(label: t.battery, value: '${vehicle.batteryPercent}%'),
                        _InfoRow(label: t.temperature, value: '${vehicle.temp.toStringAsFixed(1)}°C'),
                        _InfoRow(label: t.humidity, value: '${vehicle.hum.toStringAsFixed(1)}%'),
                        _InfoRow(label: t.dust, value: vehicle.dust.toStringAsFixed(1)),
                        _InfoRow(
                          label: t.status,
                          value: vehicle.isLocked
                              ? (session.isPaused ? t.lockedTemporarily : t.locked)
                              : t.unlocked,
                        ),
                        _InfoRow(label: t.remainingTime, value: _formatSeconds(ride.liveRemainingSeconds)),
                        if (session.overtimePenaltyAmount > 0)
                          _InfoRow(label: t.overtimeFee, value: '${session.overtimePenaltyAmount} đ'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: session.isPaused ? ride.resumeRide : ride.pauseRide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(session.isPaused ? t.resumeUse : t.pauseUse),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: ride.endRide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(t.stopUse),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatSeconds(int seconds) {
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
              child: Text(
                t.extendWarning,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
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
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFFB42318),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
          Expanded(child: Text(label, style: const TextStyle(color: Colors.black54))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
