/*
 * @file       parking_zone.dart
 * @brief      Parking zone shared via Firestore (collection: parking_zones).
 *             Same shape as the web admin tool so both projects read the
 *             same documents.
 */

/* Imports ------------------------------------------------------------ */
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class ParkingZone {
  final String id;
  final String name;
  final LatLng point;
  final double radiusMeters;
  final String address;
  final bool isActive;

  const ParkingZone({
    required this.id,
    required this.name,
    required this.point,
    required this.radiusMeters,
    this.address = '',
    this.isActive = true,
  });

  factory ParkingZone.fromMap(String id, Map<String, dynamic> map) {
    final double lat = _asDouble(map['lat']) ?? 0.0;
    final double lng = _asDouble(map['lng']) ?? 0.0;
    return ParkingZone(
      id: id,
      name: (map['name'] ?? id).toString(),
      point: LatLng(lat, lng),
      radiusMeters: _asDouble(map['radiusMeters']) ?? 50.0,
      address: (map['address'] ?? '').toString(),
      isActive: map['isActive'] is bool ? map['isActive'] as bool : true,
    );
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is Timestamp) return null;
    return double.tryParse(value.toString());
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
