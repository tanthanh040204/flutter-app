/*
 * @file       ble_frag_codec.dart
 * @brief      Mirrors the firmware BLE fragmentation (new_network.md §4):
 *             a 2-byte header per packet — [seq][bit7=LAST bit6=FIRST
 *             bits5..0=channel] — then up to 200 payload bytes. Pure logic,
 *             no platform deps, fully unit-tested.
 */

/* Imports ------------------------------------------------------------ */
import '../config/ble_config.dart';

/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */
/* Public classes ----------------------------------------------------- */

class BleFragCodec {
  BleFragCodec._();

  static List<List<int>> fragment(int channel, List<int> payload, int seq0) {
    final int total = payload.length;
    final int count = total == 0
        ? 1
        : (total + kBleFragMaxPayload - 1) ~/ kBleFragMaxPayload;

    final List<List<int>> packets = [];
    for (int i = 0; i < count; i++) {
      final int start = i * kBleFragMaxPayload;
      final int end = (start + kBleFragMaxPayload) < total
          ? (start + kBleFragMaxPayload)
          : total;

      int flags = channel & kBleChannelMask;
      if (i == 0) flags |= kBleFlagFirst;
      if (i == count - 1) flags |= kBleFlagLast;

      packets.add([
        (seq0 + i) & 0xFF,
        flags,
        ...payload.sublist(start, end),
      ]);
    }
    return packets;
  }
}


class BleReassembler {
  /* --- private fields ------------------------------------------ */
  final List<int> _buf = [];
  int _channel = 0;
  bool _active = false;

  /* --- public methods ------------------------------------------ */
  (int, List<int>)? add(List<int> packet) {
    if (packet.length < kBleFragHeaderLen) return null;

    final int flags = packet[1];
    final bool isFirst = (flags & kBleFlagFirst) != 0;
    final bool isLast = (flags & kBleFlagLast) != 0;
    final int channel = flags & kBleChannelMask;

    if (isFirst) {
      _buf.clear();
      _channel = channel;
      _active = true;
    }
    if (!_active) return null; /* fragment before any FIRST → drop */

    _buf.addAll(packet.sublist(kBleFragHeaderLen));

    if (isLast) {
      final result = (_channel, List<int>.of(_buf));
      _buf.clear();
      _active = false;
      return result;
    }
    return null;
  }

  void reset() {
    _buf.clear();
    _active = false;
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
