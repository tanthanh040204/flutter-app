/*
 * @file       mobile_telemetry_provider.dart
 * @brief      Subscribes to bike_id/data, parses MCU telemetry (including the
 *             new totalKm field), and stores the latest snapshot per bike.
 *             totalKm is parsed and persisted in memory but not yet surfaced
 *             in any UI — it's reserved for future features.
 */

/* Imports ------------------------------------------------------------ */
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/feature_conf.dart';
import '../config/mqtt_config.dart';
import '../models/device_telemetry.dart';
import '../services/mqtt_service.dart';
import '../services/telemetry_parser.dart';

/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class MobileTelemetryProvider extends ChangeNotifier {
  MobileTelemetryProvider(this._mqtt);

  /* --- private fields ------------------------------------------ */
  final MqttService _mqtt;
  final Map<String, DeviceTelemetry> _latest = {};
  final Map<String, StreamSubscription<String>> _subs = {};

  /* --- public methods ------------------------------------------ */
  DeviceTelemetry? telemetryFor(String bikeId) => _latest[bikeId];

  void ingestRaw(String bikeId, String raw) {
    final DeviceTelemetry? parsed = TelemetryParser.parse(raw);
    if (parsed == null) return;
    _latest[bikeId] = parsed;
    notifyListeners();
  }

  /* Begin storing telemetry for `bikeId`. Idempotent — calling twice
   * with the same id is a no-op. */
  void watch(String bikeId) {
    if (_subs.containsKey(bikeId)) return;
    final String topic = MqttTopics.deviceData(bikeId);
    if (FeatureConfig.debugTelemetryLog) {
      debugPrint('[Telemetry] subscribe data topic: $topic');
    }
    _subs[bikeId] = _mqtt.rawStreamOf(topic).listen((raw) {
      final DeviceTelemetry? parsed = TelemetryParser.parse(raw);
      if (parsed == null) return;
      _latest[bikeId] = parsed;
      notifyListeners();
    });
  }

  void stopWatching(String bikeId) {
    _subs.remove(bikeId)?.cancel();
    _mqtt.unsubscribe(MqttTopics.deviceData(bikeId));
  }

  @override
  void dispose() {
    for (final StreamSubscription<String> sub in _subs.values) {
      sub.cancel();
    }
    _subs.clear();
    super.dispose();
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
