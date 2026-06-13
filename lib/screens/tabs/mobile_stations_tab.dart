/*
 * @file       mobile_stations_tab.dart
 * @brief      Stations tab: renders a map of bike stations and details sheet.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_strings.dart';
import '../../models/device_telemetry.dart';
import '../../models/station.dart';
import '../../providers/mobile_ride_provider.dart';
import '../../providers/mobile_stations_provider.dart';
import '../../providers/mobile_telemetry_provider.dart';

/* Constants ---------------------------------------------------------- */
const Color kMarkerColor = Color(0xFF1557FF);
const Color kAccentColor = Color(0xFF1557FF);
const String kOsmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String kUserAgentPkg = 'com.example.UTE-go_user_app';
const int kBatteryHighThresh = 60;
const int kBatteryMediumThresh = 25;

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class MobileStationsTab extends StatefulWidget {
  const MobileStationsTab({super.key});

  @override
  State<MobileStationsTab> createState() => _MobileStationsTabState();
}

class _MobileStationsTabState extends State<MobileStationsTab> {
  final MapController _mapController = MapController();
  /* Tracks the bike we last centred on, so we recenter only once per ride. */
  String? _focusedBikeId;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings t = context.tr;
    final MobileStationsProvider stationsProvider = context
        .watch<MobileStationsProvider>();
    final MobileRideProvider ride = context.watch<MobileRideProvider>();
    final MobileTelemetryProvider telemetry = context
        .watch<MobileTelemetryProvider>();

    final List<BikeStation> stations = stationsProvider.stations;
    final LatLng userPoint = stationsProvider.currentUserLocation;

    /* While renting, overlay the rented bike's live position + travelled
     * route. Outside a rental the map behaves exactly as before. */
    final bool renting = ride.hasActiveSession && ride.currentBikeId != null;
    final String? bikeId = renting ? ride.currentBikeId : null;
    final DeviceTelemetry? tm = bikeId != null
        ? telemetry.telemetryFor(bikeId)
        : null;
    final LatLng? bikePoint = (tm?.lat != null && tm?.lng != null)
        ? LatLng(tm!.lat!, tm.lng!)
        : null;
    final List<LatLng> bikePath = bikeId != null
        ? telemetry.pathFor(bikeId)
        : const [];

    if (renting && bikePoint != null && _focusedBikeId != bikeId) {
      _focusedBikeId = bikeId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapController.move(bikePoint, 16);
      });
    }
    if (!renting) _focusedBikeId = null;

    final LatLng center =
        bikePoint ?? (stations.isNotEmpty ? stations.first.point : userPoint);

    return Scaffold(
      appBar: AppBar(title: Text(t.stations)),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: center, initialZoom: 15.2),
        children: [
          TileLayer(
            urlTemplate: kOsmTileUrl,
            userAgentPackageName: kUserAgentPkg,
          ),
          if (bikePath.length >= 2)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: bikePath,
                  strokeWidth: 5,
                  color: kAccentColor,
                ),
              ],
            ),
          MarkerLayer(
            markers: [
              Marker(
                point: userPoint,
                width: 70,
                height: 70,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.red,
                  size: 38,
                ),
              ),
              ...stations.map(
                (station) => Marker(
                  point: station.point,
                  width: 64,
                  height: 64,
                  child: GestureDetector(
                    onTap: () => _showStationSheet(context, station),
                    child: _StationMarker(count: station.bikeCount),
                  ),
                ),
              ),
              if (bikePoint != null)
                Marker(
                  point: bikePoint,
                  width: 54,
                  height: 54,
                  alignment: Alignment.topCenter,
                  child: const _RentedBikeMarker(),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.read<MobileStationsProvider>().refreshUserLocation(),
        icon: const Icon(Icons.refresh),
        label: Text(t.refresh),
      ),
    );
  }

  Future<void> _showStationSheet(
    BuildContext context,
    BikeStation station,
  ) async {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        builder: (context, scrollController) {
          final AppStrings t = context.tr;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
            controller: scrollController,
            children: [
              Text(
                station.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: kAccentColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                station.address,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StationStat(
                      label: t.bikesAvailable,
                      value: station.bikeCount.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StationStat(
                      label: t.freeSlots,
                      value: station.availableSlots.toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final Uri uri = Uri.parse(station.googleMapUrl);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: Text(t.openGoogleMaps),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                t.bikesAtStation,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              ...station.vehicles.map(
                (bike) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.pedal_bike,
                        color: kAccentColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bike.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.bikeBatteryText(bike.status, bike.batteryPercent),
                              style: TextStyle(
                                color: _batteryColor(bike.batteryPercent),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _batteryColor(int percent) {
    if (percent >= kBatteryHighThresh) return Colors.green;
    if (percent >= kBatteryMediumThresh) return Colors.orange;
    return Colors.red;
  }
}

/* Private classes ---------------------------------------------------- */
class _RentedBikeMarker extends StatelessWidget {
  const _RentedBikeMarker();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.location_pin,
      color: Color(0xFF1F2A44),
      size: 48,
      shadows: [
        Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
      ],
    );
  }
}

class _StationMarker extends StatelessWidget {
  final int count;

  const _StationMarker({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: kMarkerColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.pedal_bike, color: Colors.white, size: 24),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StationStat extends StatelessWidget {
  final String label;
  final String value;

  const _StationStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: kAccentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}

/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
