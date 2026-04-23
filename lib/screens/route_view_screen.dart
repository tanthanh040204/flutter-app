/*
 * @file       route_view_screen.dart
 * @brief      Screen rendering a recorded ride route on a tile map.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
    final LatLng center = route.points.isNotEmpty
        ? route.points.first
        : kDefaultRouteCenter;

    return Scaffold(
      appBar: AppBar(title: Text(route.buttonLabel)),
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
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
