/*
 * @file       device_telemetry.dart
 * @brief      Snapshot of MCU telemetry parsed from the bike_id/data topic.
 */

/* Imports ------------------------------------------------------------ */
/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class DeviceTelemetry {
  final double? lat;
  final double? lng;
  final DateTime timestamp;

  final double? battery;
  final double? velocityMs;
  final double? velocityKmh;
  final double? distanceM;
  /* Not yet surfaced in the UI — stored for future features. */
  final double? totalKm;
  final double? directionDeg;
  final String? directionStr;
  final double? dust;
  final double? temp;
  final double? hum;

  const DeviceTelemetry({
    this.lat,
    this.lng,
    required this.timestamp,
    this.battery,
    this.velocityMs,
    this.velocityKmh,
    this.distanceM,
    this.totalKm,
    this.directionDeg,
    this.directionStr,
    this.dust,
    this.temp,
    this.hum,
  });
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
