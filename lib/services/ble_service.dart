/*
 * @file       ble_service.dart
 * @brief      Pure BLE transport over flutter_blue_plus: scan (by Tracker
 *             Service UUID + name), connect, handshake, notify-reassemble
 *             (DATA/NOTI), and framed command write to CMD. No relay/topic
 *             logic here — see BleRelayProvider. Guarded so web/unsupported
 *             platforms are a safe no-op.
 */

/* Imports ------------------------------------------------------------ */
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../config/ble_config.dart';
import '../config/feature_conf.dart';
import 'ble_frag_codec.dart';

/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */

enum BleLinkState { disconnected, connecting, connected, ready }

/* Typedef / Function types ------------------------------------------ */
/* Public classes ----------------------------------------------------- */

class BleService {
  BleService();

  /* --- private fields ------------------------------------------ */
  BluetoothDevice? _device;
  BluetoothCharacteristic? _cmdChar;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  final List<StreamSubscription<List<int>>> _notifySubs = [];
  final BleReassembler _dataReasm = BleReassembler();
  final BleReassembler _notiReasm = BleReassembler();
  int _outSeq = 0;

  final StreamController<(int, List<int>)> _inboundCtl =
      StreamController<(int, List<int>)>.broadcast();
  final StreamController<BleLinkState> _linkCtl =
      StreamController<BleLinkState>.broadcast();

  /* --- public getters ------------------------------------------ */
  /* Reassembled uplink frames: (channel, payload) for DATA/NOTI. */
  Stream<(int, List<int>)> get inbound => _inboundCtl.stream;
  Stream<BleLinkState> get link => _linkCtl.stream;

  /* --- public methods ------------------------------------------ */
  /* True only where BLE can actually run (not web, adapter supported). */
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      return await FlutterBluePlus.isSupported;
    } catch (e) {
      _log('isSupported failed: $e');
      return false;
    }
  }

  Future<String?> scanForName(String wantName, Duration window) async {
    final Completer<String?> done = Completer<String?>();
    try {
      await _scanSub?.cancel();
      _scanSub = FlutterBluePlus.onScanResults.listen((results) {
        for (final ScanResult r in results) {
          final String name = r.advertisementData.advName.isNotEmpty
              ? r.advertisementData.advName
              : r.device.platformName;
          _scanLog('saw "$name" (${r.device.remoteId.str}) rssi=${r.rssi}');
          if (name == wantName && !done.isCompleted) {
            done.complete(r.device.remoteId.str);
          }
        }
      });
      await FlutterBluePlus.startScan(timeout: window);
      /* Wait for a name match, or the scan window (+grace) to elapse. */
      return await done.future.timeout(
        window + const Duration(seconds: 1),
        onTimeout: () => null,
      );
    } catch (e) {
      _log('scan failed: $e');
      return null;
    } finally {
      await _scanSub?.cancel();
      _scanSub = null;
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
    }
  }

  Future<void> connectAndHandshake(String remoteId) async {
    _linkCtl.add(BleLinkState.connecting);
    final BluetoothDevice device = BluetoothDevice.fromId(remoteId);
    _device = device;

    await _connSub?.cancel();
    _connSub = device.connectionState.listen((s) {
      if (s == BluetoothConnectionState.disconnected) {
        _linkCtl.add(BleLinkState.disconnected);
      }
    });

    await device.connect(timeout: const Duration(seconds: 12));
    _linkCtl.add(BleLinkState.connected);

    try {
      await device.requestMtu(kBleFragMtu);
    } catch (e) {
      _log('requestMtu failed (continuing): $e');
    }

    final List<BluetoothService> services = await device.discoverServices();
    /* Dump the real GATT layout so the actual 128-bit UUIDs can be read
     * off the device and pasted into ble_config.dart (firmware never
     * shipped them to us). */
    for (final BluetoothService s in services) {
      _log('svc ${s.uuid.str}');
      for (final BluetoothCharacteristic c in s.characteristics) {
        _log('  char ${c.uuid.str}');
      }
    }
    final BluetoothService svc = services.firstWhere(
      (s) => _sameUuid(s.uuid, kBleServiceUuid),
      orElse: () => throw StateError('Tracker service not found'),
    );

    BluetoothCharacteristic? data, noti, cmd;
    for (final BluetoothCharacteristic c in svc.characteristics) {
      if (_sameUuid(c.uuid, kBleCharData)) data = c;
      if (_sameUuid(c.uuid, kBleCharNoti)) noti = c;
      if (_sameUuid(c.uuid, kBleCharCmd)) cmd = c;
    }
    if (data == null || noti == null || cmd == null) {
      throw StateError('Tracker characteristics incomplete');
    }
    _cmdChar = cmd;

    await _subscribe(data, _dataReasm);
    await _subscribe(noti, _notiReasm);

    /* Raw 2-byte handshake (ble_feature.md §14.3) — not framed. */
    await cmd.write(kBleHandshakeMagic, withoutResponse: false);
    _linkCtl.add(BleLinkState.ready);
    _log('handshake written, relay ready');
  }

  /* Fragments [payload] (channel 0 — device ignores it inbound) and writes
   * the packets to CMD in order. */
  Future<bool> sendCommand(List<int> payload) async {
    final BluetoothCharacteristic? cmd = _cmdChar;
    if (cmd == null) return false;
    final List<List<int>> packets =
        BleFragCodec.fragment(kBleChData, payload, _outSeq);
    _outSeq = (_outSeq + packets.length) & 0xFF;
    try {
      for (final List<int> p in packets) {
        await cmd.write(p, withoutResponse: false);
      }
      return true;
    } catch (e) {
      _log('sendCommand failed: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    for (final StreamSubscription<List<int>> s in _notifySubs) {
      await s.cancel();
    }
    _notifySubs.clear();
    await _connSub?.cancel();
    _connSub = null;
    _dataReasm.reset();
    _notiReasm.reset();
    _cmdChar = null;
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    _linkCtl.add(BleLinkState.disconnected);
  }

  void dispose() {
    _scanSub?.cancel();
    disconnect();
    _inboundCtl.close();
    _linkCtl.close();
  }

  /* --- private methods ----------------------------------------- */
  Future<void> _subscribe(
    BluetoothCharacteristic c,
    BleReassembler reasm,
  ) async {
    await c.setNotifyValue(true);
    _notifySubs.add(
      c.onValueReceived.listen((bytes) {
        final (int, List<int>)? msg = reasm.add(bytes);
        if (msg != null) _inboundCtl.add(msg);
      }),
    );
  }

  bool _sameUuid(Guid g, String uuid) => g == Guid(uuid);
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
void _log(String msg) {
  if (FeatureConfig.debugBleLog) debugPrint('[Ble] $msg');
}

/* Per-device scan spam — separate, noisier gate. */
void _scanLog(String msg) {
  if (FeatureConfig.debugBleScanLog) debugPrint('[Ble] $msg');
}

/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
