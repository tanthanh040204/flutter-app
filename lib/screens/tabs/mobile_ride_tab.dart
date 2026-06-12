/*
 * @file       mobile_ride_tab.dart
 * @brief      Ride tab: shows the current rental state and its controls.
 *             Vehicle telemetry will arrive via bike_id/data once wired.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/device_telemetry.dart';
import '../../models/error_codes.dart';
import '../../providers/mobile_ride_provider.dart';
import '../../providers/mobile_telemetry_provider.dart';
import '../../services/protocol_codec.dart';

/* Constants ---------------------------------------------------------- */
const Color kRideBlue = Color(0xFF2563EB);
const Color kRideCyan = Color(0xFF06B6D4);
const Color kRideGreen = Color(0xFF16A34A);
const Color kRideOrange = Color(0xFFF97316);

/* Public classes ----------------------------------------------------- */
class MobileRideTab extends StatelessWidget {
  const MobileRideTab({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStrings t = context.tr;
    final MobileRideProvider ride = context.watch<MobileRideProvider>();
    /* Watch telemetry so the data card rebuilds as new snapshots arrive. */
    context.watch<MobileTelemetryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.rideStats),
        actions: ride.hasActiveSession
            ? [
                Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, size: 20),
                    Switch(
                      value: ride.dangerNotiEnabled,
                      onChanged: ride.setDangerNoti,
                    ),
                  ],
                ),
                IconButton(
                  tooltip: t.findVehicle,
                  icon: const Icon(Icons.my_location),
                  onPressed: ride.findVehicle,
                ),
                const SizedBox(width: 4),
              ]
            : null,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC), Colors.white],
          ),
        ),
        child: !ride.hasActiveSession
            ? _EmptyRideState(title: t.notUsingBike, description: t.noRideDesc)
            : _buildContent(context, ride),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MobileRideProvider ride) {
    final AppStrings t = context.tr;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (ride.warning != null) _buildWarning(context, ride),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kRideBlue, kRideCyan],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: kRideBlue.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.electric_bike, color: Colors.white, size: 34),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.vehicleLabel(ride.currentBikeId ?? ''),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ride.isPaused ? t.pause : t.unlocked,
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                _formatSeconds(ride.liveRemainingSeconds),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t.remainingTimeDesc,
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.info_outline,
                color: kRideBlue,
                label: t.status,
                value: ride.isPaused ? t.pause : t.unlocked,
              ),
              _InfoRow(
                icon: Icons.price_change_outlined,
                color: kRideOrange,
                label: t.pricePerHour,
                value:
                    '${t.pricePerHourAmount(ride.effectivePricePerHour)}'
                    '${ride.isPaused ? t.pauseDiscountSuffix : ''}',
              ),
              _InfoRow(
                icon: Icons.timer_outlined,
                color: kRideGreen,
                label: t.remainingTime,
                value: _formatSeconds(ride.liveRemainingSeconds),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildTelemetryCard(context, ride.latestTelemetry),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: ride.isPaused ? ride.resumeRide : ride.pauseRide,
                icon: Icon(ride.isPaused ? Icons.play_arrow : Icons.pause),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(ride.isPaused ? t.resumeUse : t.pauseUse),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: ride.phase == RentalPhase.stopping ? null : ride.endRide,
                icon: const Icon(Icons.stop_circle_outlined),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    ride.phase == RentalPhase.stopping
                        ? t.processing
                        : t.stopUse,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTelemetryCard(BuildContext context, DeviceTelemetry? tm) {
    final AppStrings t = context.tr;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.speed,
            color: kRideBlue,
            label: t.speed,
            value: _fmt(tm?.velocityKmh, 'km/h', decimals: 1),
          ),
          _InfoRow(
            icon: Icons.route_outlined,
            color: kRideCyan,
            label: t.distanceTraveled,
            value: _fmt(tm?.distanceM, 'm', decimals: 0),
          ),
          _InfoRow(
            icon: Icons.thermostat,
            color: kRideOrange,
            label: t.temperature,
            value: _fmt(tm?.temp, '°C', decimals: 1),
          ),
          _InfoRow(
            icon: Icons.water_drop_outlined,
            color: kRideBlue,
            label: t.humidity,
            value: _fmt(tm?.hum, '%', decimals: 0),
          ),
          _InfoRow(
            icon: Icons.grain,
            color: kRideGreen,
            label: t.dust,
            value: _fmt(tm?.dust, 'µg/m³', decimals: 1),
          ),
        ],
      ),
    );
  }

  String _fmt(double? value, String unit, {int decimals = 1}) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(decimals)} $unit';
  }

  Widget _buildWarning(BuildContext context, MobileRideProvider ride) {
    final String w = ride.warning!;
    final bool severe = w == kEvtWarnOutOfBalance || w == kErrOutOfParkingZone;
    final Color color = severe ? Colors.red : Colors.orange;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(severe ? Icons.error : Icons.warning_amber, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleFor(w, context.tr),
                    style: TextStyle(color: color, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(_bodyFor(w, context.tr), style: const TextStyle(height: 1.35)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: ride.clearWarning,
            ),
          ],
        ),
      ),
    );
  }

  String _titleFor(String code, AppStrings t) {
    switch (code) {
      case kEvtWarnLowBalance:
        return t.balanceRunningLowTitle;
      case kEvtWarnOutOfBalance:
        return t.outOfBalanceTitle;
      case kErrOutOfParkingZone:
        return t.outOfParkingZoneTitle;
      default:
        return t.warning;
    }
  }

  String _bodyFor(String code, AppStrings t) {
    switch (code) {
      case kEvtWarnLowBalance:
        return t.lowBalanceBody;
      case kEvtWarnOutOfBalance:
        return t.outOfBalanceBody;
      case kErrOutOfParkingZone:
        return t.outOfParkingZoneBody;
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
class _EmptyRideState extends StatelessWidget {
  final String title;
  final String description;

  const _EmptyRideState({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: kRideBlue.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.electric_bike_outlined, color: kRideBlue, size: 46),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/* End of file -------------------------------------------------------- */
