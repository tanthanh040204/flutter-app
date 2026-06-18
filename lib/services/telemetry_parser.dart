/*
 * @file       telemetry_parser.dart
 * @brief      Parses the MCU /data MQTT payload (standard JSON) into
 *             DeviceTelemetry. Mirrors the parser used by flutter-web so the
 *             app understands the same wire format.
 *
 *             Expected payload (firmware v2):
 *               {"time":"2026/05/07-22:38:21","battery":46.6,
 *                "velocity_ms":0.0,"velocity_kmh":0.0,"distance_m":0.0,
 *                "totalKm":0.0,"direction_deg":233.0,"direction_str":"SW",
 *                "position":[10.853079,106.782715],
 *                "dust":0.7,"temp":33.1,"hum":67.8}
 */

/* Imports ------------------------------------------------------------ */
import 'dart:convert';
import 'dart:developer' as dev;

import '../models/device_telemetry.dart';

/* Constants ---------------------------------------------------------- */
const int kRawPreviewLength = 120;

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class TelemetryParser {
  const TelemetryParser._();

  /* --- public methods ------------------------------------------ */
  static DeviceTelemetry? parse(String raw) {
    if (raw.isEmpty) return null;
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return _normalize(decoded);
    } catch (e) {
      final String preview = raw.length > kRawPreviewLength
          ? raw.substring(0, kRawPreviewLength)
          : raw;
      dev.log(
        '[TelemetryParser] parse failed: $e\n  raw($kRawPreviewLength): $preview',
        name: 'TelemetryParser',
      );
      return null;
    }
  }

  /* --- private methods ----------------------------------------- */
  static DeviceTelemetry _normalize(Map<String, dynamic> json) {
    final (double?, double?) pos = _parsePosition(json['position']);
    final DateTime ts = _parseTime(json['time']?.toString()) ?? DateTime.now();

    return DeviceTelemetry(
      lat: pos.$1,
      lng: pos.$2,
      timestamp: ts,
      battery: _toD(json['battery']),
      velocityMs: _toD(json['velocity_ms']),
      velocityKmh: _toD(json['velocity_kmh']),
      distanceM: _toD(json['distance_m']),
      totalKm: _toD(json['totalKm']),
      directionDeg: _toD(json['direction_deg']),
      directionStr: json['direction_str']?.toString(),
      dust: _toD(json['dust']),
      temp: _toD(json['temp']),
      hum: _toD(json['hum']),
    );
  }

  static double? _toD(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  // Parse [lat, lng] array → (lat, lng). Drops (0,0) sentinel "no GPS fix".
  static (double?, double?) _parsePosition(dynamic raw) {
    if (raw is! List || raw.length < 2) return (null, null);
    final double? lat = _toD(raw[0]);
    final double? lng = _toD(raw[1]);
    if (lat == null || lng == null) return (null, null);
    if (lat.isNaN || lng.isNaN) return (null, null);
    if (lat == 0 && lng == 0) return (null, null);
    return (lat, lng);
  }

  // Parse "YYYY/M/D-HH:MM:SS" → DateTime | null.
  static DateTime? _parseTime(String? str) {
    if (str == null || str.isEmpty) return null;
    final m = RegExp(r'(\d+)/(\d+)/(\d+)-(\d+):(\d+):(\d+)').firstMatch(str);
    if (m == null) return null;
    final int y = int.parse(m.group(1)!);
    final int mo = int.parse(m.group(2)!);
    final int d = int.parse(m.group(3)!);
    final int h = int.parse(m.group(4)!);
    final int mi = int.parse(m.group(5)!);
    final int s = int.parse(m.group(6)!);

    // Sentinel "no GPS fix" — firmware sends epoch-ish defaults before lock.
    if (y <= 2000 || mo == 0 || d == 0) return null;

    try {
      return DateTime(y, mo, d, h, mi, s);
    } catch (_) {
      return null;
    }
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
