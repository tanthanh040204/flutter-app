/*
 * @file       mobile_ride_tab.dart
 * @brief      Ride tab: shows the current rental state and its controls.
 *             Vehicle telemetry will arrive via bike_id/data once wired.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/error_codes.dart';
import '../../providers/mobile_ride_provider.dart';
import '../../services/protocol_codec.dart';
import '../../models/device_telemetry.dart';

/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class MobileRideTab extends StatelessWidget {
  const MobileRideTab({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStrings t = context.tr;
    final MobileRideProvider ride = context.watch<MobileRideProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(t.rideStats)),
      body: !ride.hasActiveSession
          ? Center(
              child: Text(
                t.notUsingBike,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            )
          : _buildContent(context, ride),
    );
  }

  Widget _buildContent(BuildContext context, MobileRideProvider ride) {
    DeviceTelemetry? telemetry = ride.latestTelemetry;
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
                  'Bike ${ride.currentBikeId ?? ''}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 14),
                _InfoRow(
                  label: context.tr.status,
                  value: ride.isPaused ? context.tr.pause : context.tr.unlocked,
                ),
                _InfoRow(
                  label: context.tr.pricePerHour,
                  value:
                      '${ride.effectivePricePerHour}đ/hour'
                      '${ride.isPaused ? ' (50% off)' : ''}',
                ),
                _InfoRow(
                  label: context.tr.remainingTime,
                  value: _formatSeconds(ride.liveRemainingSeconds),
                ),
                _InfoRow(
                  label: context.tr.velocityMs,
                  value: telemetry?.velocityMs != null
                      ? '${telemetry!.velocityMs} m/s'
                      : 'N/A',
                ),
                _InfoRow(
                  label: context.tr.velocityKmh,
                  value: telemetry?.velocityKmh != null
                      ? '${telemetry!.velocityKmh} km/h'
                      : 'N/A',
                ),
                _InfoRow(
                  label: context.tr.distanceM,
                  value: telemetry?.distanceM != null
                      ? '${telemetry!.distanceM} m'
                      : 'N/A',
                ),
                _InfoRow(
                  label: context.tr.position,
                  value: telemetry?.lat != null && telemetry?.lng != null
                      ? '(${telemetry!.lat}, ${telemetry.lng})'
                      : 'N/A',
                ),
                _InfoRow(
                  label: context.tr.temperature,
                  value: telemetry?.temp != null
                      ? '${telemetry!.temp}°C'
                      : 'N/A',
                ),
                _InfoRow(
                  label: context.tr.humidity,
                  value: telemetry?.hum != null ? '${telemetry!.hum}%' : 'N/A',
                ),
                _InfoRow(
                  label: context.tr.dust,
                  value: telemetry?.dust != null
                      ? '${telemetry!.dust} μg/m³'
                      : 'N/A',
                ),
                _InfoRow(
                  label: context.tr.direction,
                  value:
                      telemetry?.directionDeg != null ||
                          telemetry?.directionStr != null
                      ? '${telemetry!.directionDeg}°${telemetry!.directionStr}'
                      : 'N/A',
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
              ride.isPaused ? context.tr.resumeUse : context.tr.pauseUse,
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
                  ? context.tr.processing
                  : context.tr.stopUse,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarning(MobileRideProvider ride) {
    final String w = ride.warning!;
    final bool severe = w == kEvtWarnOutOfBalance || w == kErrOutOfParkingZone;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: severe ? Colors.red.shade50 : Colors.orange.shade50,
        child: ListTile(
          leading: Icon(
            severe ? Icons.error : Icons.warning_amber,
            color: severe ? Colors.red : Colors.orange,
          ),
          title: Text(_titleFor(w)),
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
      case kEvtWarnLowBalance:
        return 'Balance running low';
      case kEvtWarnOutOfBalance:
        return 'Out of balance — return the bike';
      case kErrOutOfParkingZone:
        return 'Outside a valid parking zone';
      default:
        return 'Warning';
    }
  }

  String _bodyFor(String code) {
    switch (code) {
      case kEvtWarnLowBalance:
        return 'You only have enough for the current block. Please top up.';
      case kEvtWarnOutOfBalance:
        return 'Return the bike to a parking zone within 15 minutes to '
            'avoid a penalty.';
      case kErrOutOfParkingZone:
        return 'Move the bike to the nearest parking zone to end the ride.';
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
