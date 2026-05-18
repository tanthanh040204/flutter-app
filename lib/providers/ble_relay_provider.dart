/*
 * @file       ble_relay_provider.dart
 * @brief      Foreground-only BLE relay orchestrator (ble_feature.md).
 *             Scans for the user's associated bike (haq-trk-<bikeId>),
 *             connects, and byte-transparently bridges:
 *               DATA  bike→BLE→ <bikeId>/data  (+ local telemetry inject)
 *               NOTI  bike→BLE→ <bikeId>/noti
 *               CMD   <bikeId>/cmd →BLE→ bike
 *             No rental/state-machine logic — that stays web-owned.
 */

/* Imports ------------------------------------------------------------ */
import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/ble_config.dart';
import '../config/feature_conf.dart';
import '../config/mqtt_config.dart';
import '../services/ble_service.dart';
import '../services/mqtt_service.dart';
import 'mobile_ride_provider.dart';
import 'mobile_telemetry_provider.dart';

/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */

enum BleRelayState { idle, scanning, connecting, relaying }

/* Typedef / Function types ------------------------------------------ */
/* Public classes ----------------------------------------------------- */

class BleRelayProvider extends ChangeNotifier with WidgetsBindingObserver {
  BleRelayProvider(this._mqtt, this._telemetry, {BleService? service})
    : _ble = service ?? BleService() {
    if (!FeatureConfig.enableBleRelay) return;
    WidgetsBinding.instance.addObserver(this);
    _linkSub = _ble.link.listen(_onLink);
    _loadPersistedThenStart();
  }

  /* --- private fields ------------------------------------------ */
  final MqttService _mqtt;
  final MobileTelemetryProvider _telemetry;
  final BleService _ble;

  StreamSubscription<BleLinkState>? _linkSub;
  StreamSubscription<(int, List<int>)>? _inboundSub;
  StreamSubscription<String>? _cmdSub;
  Timer? _cycleTimer;

  bool _available = false;
  bool _foreground = true;
  bool _scanning = false; /* a scan cycle is in flight */
  bool _tripActive = false; /* saw an active rental for the relayed bike */
  String? _target; /* bike currently targeted */
  String? _persisted; /* last-rented bike from prefs */
  BleRelayState _state = BleRelayState.idle;

  /* --- public getters ------------------------------------------ */
  BleRelayState get state => _state;
  String? get targetBikeId => _target;
  bool get isRelaying => _state == BleRelayState.relaying;

  /* --- public methods ------------------------------------------ */
  void bindRide(MobileRideProvider ride) {
    if (!FeatureConfig.enableBleRelay) return;
    if (FeatureConfig.bleDebugForceBikeId.isNotEmpty) {
      if (_target == FeatureConfig.bleDebugForceBikeId) return;
      _target = FeatureConfig.bleDebugForceBikeId;
      _resetToScanning();
      return;
    }
    final String? sessionBike = ride.currentBikeId;
    if (sessionBike != null && sessionBike != _persisted) {
      _persisted = sessionBike;
      _savePersisted(sessionBike);
    }
    if (ride.hasActiveSession) _tripActive = true;

    if (_state == BleRelayState.relaying && _tripActive && ride.isEnded) {
      _tripActive = false;
      _log('rental ended (END_RENTAL) — closing relay');
      _stopAll(keepTarget: true);
      return;
    }

    final String? next = sessionBike ?? _persisted;
    if (next == _target) {
      if (_state == BleRelayState.idle && ride.hasActiveSession) {
        _maybeStart();
      }
      return;
    }
    _target = next;
    _resetToScanning();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bool fg = state == AppLifecycleState.resumed;
    if (fg == _foreground) return;
    _foreground = fg;
    if (fg) {
      _maybeStart();
    } else {
      _stopAll(keepTarget: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSub?.cancel();
    _stopAll(keepTarget: false);
    _ble.dispose();
    super.dispose();
  }

  /* --- private methods ----------------------------------------- */
  Future<void> _loadPersistedThenStart() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _persisted = prefs.getString(kBlePrefLastBikeId);
    } catch (e) {
      _log('prefs load failed: $e');
    }
    _available = await _ble.isAvailable();
    if (FeatureConfig.bleDebugForceBikeId.isNotEmpty) {
      _target = FeatureConfig.bleDebugForceBikeId;
    } else {
      _target ??= _persisted;
    }
    _maybeStart();
  }

  Future<void> _savePersisted(String bikeId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(kBlePrefLastBikeId, bikeId);
    } catch (e) {
      _log('prefs save failed: $e');
    }
  }

  void _maybeStart() {
    if (!FeatureConfig.enableBleRelay || !_available) return;
    if (!_foreground || _target == null) return;
    if (state != BleRelayState.idle) return;
    _scheduleCycle(Duration.zero);
  }

  void _scheduleCycle(Duration delay) {
    _cycleTimer?.cancel();
    _cycleTimer = Timer(delay, _runCycle);
  }

  Future<void> _runCycle() async {
    if (!_foreground || _target == null || _scanning) return;
    if (state == BleRelayState.relaying) return;
    _scanning = true;
    _setState(BleRelayState.scanning);

    final String name = BleConfig.deviceName(_target!);
    _log('scanning for "$name" (set ESP32 adv name to this exactly)');
    String? remoteId;
    try {
      remoteId = await _ble.scanForName(name, kBleScanWindow);
    } catch (e) {
      _log('scan error: $e');
    }
    _scanning = false;

    if (state == BleRelayState.relaying || _target == null || !_foreground) {
      return;
    }
    if (remoteId == null) {
      _scheduleCycle(kBleScanGap); /* nothing found — retry after the gap */
      return;
    }

    _setState(BleRelayState.connecting);
    try {
      await _ble.connectAndHandshake(remoteId);
      /* success path continues in _onLink(ready) */
    } catch (e) {
      _log('connect failed: $e');
      await _ble.disconnect();
      _setState(BleRelayState.scanning);
      _scheduleCycle(kBleScanGap);
    }
  }

  void _onLink(BleLinkState link) {
    switch (link) {
      case BleLinkState.ready:
        _wireRelay();
        _setState(BleRelayState.relaying);
        _log('relay active for $_target');
        break;
      case BleLinkState.disconnected:
        if (state == BleRelayState.idle) break;
        _unwireRelay();
        _setState(BleRelayState.scanning);
        if (_foreground && _target != null) _scheduleCycle(kBleScanGap);
        break;
      case BleLinkState.connecting:
      case BleLinkState.connected:
        break;
    }
  }

  void _wireRelay() {
    final String bike = _target!;
    _inboundSub?.cancel();
    _inboundSub = _ble.inbound.listen((frame) {
      final (int channel, List<int> bytes) = frame;
      final String payload = utf8.decode(bytes, allowMalformed: true);
      if (channel == kBleChData) {
        _mqtt.publish(MqttTopics.deviceData(bike), payload);
        _telemetry.ingestRaw(bike, payload); /* direct, no broker round-trip */
      } else {
        _mqtt.publish(MqttTopics.deviceNoti(bike), payload);
      }
    });
    _cmdSub?.cancel();
    _cmdSub = _mqtt.rawStreamOf(MqttTopics.deviceCmd(bike)).listen((raw) {
      _ble.sendCommand(utf8.encode(raw));
    });
  }

  void _unwireRelay() {
    _inboundSub?.cancel();
    _inboundSub = null;
    _cmdSub?.cancel();
    _cmdSub = null;
    if (_target != null) _mqtt.unsubscribe(MqttTopics.deviceCmd(_target!));
  }

  void _resetToScanning() {
    _unwireRelay();
    _cycleTimer?.cancel();
    _scanning = false;
    _tripActive = false;
    _ble.disconnect();
    _state = BleRelayState.idle;
    _maybeStart();
  }

  void _stopAll({required bool keepTarget}) {
    _cycleTimer?.cancel();
    _unwireRelay();
    _scanning = false;
    _tripActive = false;
    _ble.disconnect();
    if (!keepTarget) _target = null;
    _setState(BleRelayState.idle);
  }

  void _setState(BleRelayState s) {
    if (_state == s) return;
    _state = s;
    notifyListeners();
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */

void _log(String msg) {
  if (FeatureConfig.debugBleLog) debugPrint('[BleRelay] $msg');
}

/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
