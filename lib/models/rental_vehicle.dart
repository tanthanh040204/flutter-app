/*
 * @file       rental_vehicle.dart
 * @brief      Data model describing a rentable electric vehicle.
 */

/* Imports ------------------------------------------------------------ */
import 'package:latlong2/latlong.dart';

/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class RentalVehicle {
  final String id;
  final String name;
  final int batteryPercent;
  final bool isLocked;
  final bool isRunning;
  final bool isPaused;
  final bool isInUse;
  final String? currentUserId;
  final String? currentSessionId;
  final double totalKm;
  final double temp;
  final double hum;
  final double dust;
  final LatLng lastLocation;
  final DateTime updatedAt;

  const RentalVehicle({
    required this.id,
    required this.name,
    required this.batteryPercent,
    required this.isLocked,
    required this.isRunning,
    required this.isPaused,
    required this.isInUse,
    required this.currentUserId,
    required this.currentSessionId,
    required this.totalKm,
    required this.temp,
    required this.hum,
    required this.dust,
    required this.lastLocation,
    required this.updatedAt,
  });
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
