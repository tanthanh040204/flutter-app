/*
 * @file       telemetry_parser.dart
 * @brief      Parses the MCU /data MQTT payload (quasi-JSON) into
 *             DeviceTelemetry. Mirrors the parser used by flutter-web so the
 *             app understands the same wire format.
 */

/* Imports ------------------------------------------------------------ */
import 'dart:convert';
import 'dart:developer' as dev;

import '../models/device_telemetry.dart';

/* Public classes ----------------------------------------------------- */
class TelemetryParser {
  const TelemetryParser._();

  static DeviceTelemetry? parse(String raw) {
    if (raw.isEmpty) return null;
    try {
      final fixed = _preProcess(raw.trim());
      final dynamic decoded = jsonDecode(fixed);
      if (decoded is! Map<String, dynamic>) return null;
      return _normalize(decoded);
    } catch (e) {
      final preview = raw.length > 120 ? raw.substring(0, 120) : raw;
      dev.log(
        '[TelemetryParser] parse failed: $e\n  raw(120): $preview',
        name: 'TelemetryParser',
      );
      return null;
    }
  }

  /* --- private --------------------------------------------------- */
  // Same pre-processing as flutter-web: tolerate the older non-strict JSON
  // shapes ("time":[...], position:(...), unquoted direction, NaN tokens).
  static String _preProcess(String s) {
    if (!s.startsWith('{') && !s.endsWith('}')) {
      s = '{$s}';
    } else if (!s.startsWith('{')) {
      s = '{$s';
    } else if (!s.endsWith('}')) {
      s = '$s}';
    }

    s = s.replaceAllMapped(
      RegExp(r'"time"\s*:\s*\[([^\]]*)\]'),
      (m) => '"time":"${m.group(1)}"',
    );
    s = s.replaceAllMapped(
      RegExp(r'"direction"\s*:\s*([\d.]+)\s+([A-Z?]+)(?=[,}])'),
      (m) => '"direction":"${m.group(1)} ${m.group(2)}"',
    );
    s = s.replaceAllMapped(
      RegExp(r'"position"\s*:\s*\(([^)]+)\)'),
      (m) => '"position":"(${m.group(1)})"',
    );
    s = s.replaceAll(RegExp(r':\s*[+-]?nan\b', caseSensitive: false), ':null');

    return s;
  }

  static DeviceTelemetry _normalize(Map<String, dynamic> json) {
    double? toD(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    double? lat, lng;
    final rawPos = json['position'];
    if (rawPos is List) {
      final pos = _parsePositionArray(rawPos);
      lat = pos?.$1;
      lng = pos?.$2;
    } else if (rawPos != null) {
      final pos = _parsePositionString(rawPos.toString());
      lat = pos?.$1;
      lng = pos?.$2;
    }

    DateTime ts = DateTime.now();
    final rawTime = json['time'];
    if (rawTime != null) {
      ts = _parseTime(rawTime.toString()) ?? DateTime.now();
    }

    double? directionDeg;
    String? directionStr;
    final rawDir = json['direction'];
    if (rawDir != null) {
      final dir = _parseDirection(rawDir.toString());
      directionDeg = dir?.$1;
      directionStr = dir?.$2;
    }

    return DeviceTelemetry(
      lat: lat,
      lng: lng,
      timestamp: ts,
      battery: toD(json['battery']),
      velocityMs: toD(json['velocity_ms']),
      velocityKmh: toD(json['velocity_kmh']),
      distanceM: toD(json['distance_m']),
      totalKm: toD(json['totalKm']) ?? toD(json['total_km']),
      directionDeg: directionDeg,
      directionStr: directionStr,
      dust: toD(json['dust']),
      temp: toD(json['temp']),
      hum: toD(json['hum']),
    );
  }

  static (double, double)? _parsePositionArray(List<dynamic> arr) {
    if (arr.length < 2) return null;
    final lat = double.tryParse(arr[0].toString());
    final lng = double.tryParse(arr[1].toString());
    if (lat == null || lng == null || lat.isNaN || lng.isNaN) return null;
    if (lat == 0 && lng == 0) return null;
    return (lat, lng);
  }

  static (double, double)? _parsePositionString(String str) {
    final m = RegExp(r'\(\s*([-\d.]+)\s*,\s*([-\d.]+)\s*\)').firstMatch(str);
    if (m == null) return null;
    final lat = double.tryParse(m.group(1)!);
    final lng = double.tryParse(m.group(2)!);
    if (lat == null || lng == null || lat.isNaN || lng.isNaN) return null;
    if (lat == 0 && lng == 0) return null;
    return (lat, lng);
  }

  static (double, String)? _parseDirection(String str) {
    final m = RegExp(r'^([\d.]+)\s*([A-Z?]*)$').firstMatch(str.trim());
    if (m == null) return null;
    final deg = double.tryParse(m.group(1)!);
    if (deg == null) return null;
    return (deg, m.group(2) ?? '');
  }

  static DateTime? _parseTime(String str) {
    final m = RegExp(r'(\d+)/(\d+)/(\d+)-(\d+):(\d+):(\d+)').firstMatch(str);
    if (m == null) return null;
    final a = int.parse(m.group(1)!);
    final b = int.parse(m.group(2)!);
    final c = int.parse(m.group(3)!);
    final h = int.parse(m.group(4)!);
    final mi = int.parse(m.group(5)!);
    final s = int.parse(m.group(6)!);

    int y, mo, d;
    if (a > 31) {
      y = a;
      mo = b;
      d = c;
    } else {
      d = a;
      mo = b;
      y = c;
    }
    if (y <= 2000 || mo == 0 || d == 0) return null;
    try {
      return DateTime(y, mo, d, h, mi, s);
    } catch (_) {
      return null;
    }
  }
}

/* End of file -------------------------------------------------------- */
