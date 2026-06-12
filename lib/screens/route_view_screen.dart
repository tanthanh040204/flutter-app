/*
 * @file       route_view_screen.dart
 * @brief      Screen rendering a recorded ride route on a tile map.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_strings.dart';
import '../models/mobile_history_route.dart';

/* Constants ---------------------------------------------------------- */
const String kOsmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String kUserAgentPkg = 'com.example.tngo_user_app';
const LatLng kDefaultRouteCenter = LatLng(10.7791, 106.6998);

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class RouteViewScreen extends StatelessWidget {
  final MobileHistoryRoute route;

  const RouteViewScreen({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    final AppStrings t = context.tr;
    final LatLng center = route.points.isNotEmpty
        ? route.points.first
        : kDefaultRouteCenter;

    return Scaffold(
      appBar: AppBar(title: Text(_routeButtonLabel(route, t))),
      body: FlutterMap(
        options: MapOptions(initialCenter: center, initialZoom: 15),
        children: [
          TileLayer(
            urlTemplate: kOsmTileUrl,
            userAgentPackageName: kUserAgentPkg,
          ),
          if (route.points.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: route.points,
                  strokeWidth: 5,
                  color: Colors.blue,
                ),
              ],
            ),
          if (route.points.isNotEmpty)
            MarkerLayer(
              markers: [
                Marker(
                  point: route.points.first,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.green,
                    size: 28,
                  ),
                ),
                Marker(
                  point: route.points.last,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.stop, color: Colors.red, size: 28),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _routeButtonLabel(MobileHistoryRoute route, AppStrings t) {
    final String start =
        '${_two(route.startAt.hour)}:${_two(route.startAt.minute)}'
        ' ${_two(route.startAt.day)}/${_two(route.startAt.month)}';
    if (route.endAt == null) return t.routeAt(start);
    final String end =
        '${_two(route.endAt!.hour)}:${_two(route.endAt!.minute)}'
        ' ${_two(route.endAt!.day)}/${_two(route.endAt!.month)}';
    return t.routeFromTo(start, end);
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
