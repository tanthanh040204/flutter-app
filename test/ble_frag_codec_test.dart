// Round-trip + edge coverage for the BLE fragmentation codec — the one
// place in the relay with real logic. No platform deps.

import 'package:first_flutter_project/config/ble_config.dart';
import 'package:first_flutter_project/services/ble_frag_codec.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> _seq(int n) => List<int>.generate(n, (i) => i & 0xFF);

(int, List<int>)? _roundTrip(int channel, List<int> payload, int seq0) {
  final packets = BleFragCodec.fragment(channel, payload, seq0);
  final r = BleReassembler();
  (int, List<int>)? out;
  for (final p in packets) {
    final got = r.add(p);
    if (got != null) out = got;
  }
  return out;
}

void main() {
  group('fragment packet shaping', () {
    test('payload < maxPayload → single FIRST|LAST packet', () {
      final packets = BleFragCodec.fragment(kBleChData, _seq(50), 0);
      expect(packets.length, 1);
      expect(packets[0][0], 0); // seq0
      expect(packets[0][1] & kBleFlagFirst, isNonZero);
      expect(packets[0][1] & kBleFlagLast, isNonZero);
      expect(packets[0][1] & kBleChannelMask, kBleChData);
      expect(packets[0].length, kBleFragHeaderLen + 50);
    });

    test('exactly maxPayload → still one packet', () {
      final packets =
          BleFragCodec.fragment(kBleChNoti, _seq(kBleFragMaxPayload), 7);
      expect(packets.length, 1);
      expect(packets[0][0], 7);
      expect(packets[0][1] & kBleFlagFirst, isNonZero);
      expect(packets[0][1] & kBleFlagLast, isNonZero);
    });

    test('maxPayload+1 → two packets, FIRST/LAST split, seq increments', () {
      final packets = BleFragCodec.fragment(
        kBleChData,
        _seq(kBleFragMaxPayload + 1),
        250,
      );
      expect(packets.length, 2);
      expect(packets[0][0], 250);
      expect(packets[1][0], 251);
      expect(packets[0][1] & kBleFlagFirst, isNonZero);
      expect(packets[0][1] & kBleFlagLast, 0);
      expect(packets[1][1] & kBleFlagFirst, 0);
      expect(packets[1][1] & kBleFlagLast, isNonZero);
    });

    test('empty payload → one header-only FIRST|LAST packet', () {
      final packets = BleFragCodec.fragment(kBleChData, const [], 0);
      expect(packets.length, 1);
      expect(packets[0].length, kBleFragHeaderLen);
      expect(packets[0][1] & kBleFlagFirst, isNonZero);
      expect(packets[0][1] & kBleFlagLast, isNonZero);
    });

    test('seq wraps at 256', () {
      final packets = BleFragCodec.fragment(
        kBleChData,
        _seq(kBleFragMaxPayload * 3),
        255,
      );
      expect(packets.length, 3);
      expect(packets[0][0], 255);
      expect(packets[1][0], 0);
      expect(packets[2][0], 1);
    });
  });

  group('round-trip', () {
    for (final n in [0, 1, 199, 200, 201, 200 * 3, 200 * 3 + 17, 5000]) {
      test('payload of $n bytes survives fragment→reassemble', () {
        final payload = _seq(n);
        final out = _roundTrip(kBleChData, payload, 13);
        expect(out, isNotNull);
        expect(out!.$1, kBleChData);
        expect(out.$2, payload);
      });
    }

    test('channel id is preserved', () {
      final out = _roundTrip(kBleChNoti, _seq(300), 0);
      expect(out!.$1, kBleChNoti);
    });

    test('two messages through one reassembler stay separate', () {
      final r = BleReassembler();
      final m1 = _seq(250);
      final m2 = _seq(120);
      final results = <(int, List<int>)>[];

      for (final p in BleFragCodec.fragment(kBleChData, m1, 0)) {
        final g = r.add(p);
        if (g != null) results.add(g);
      }
      for (final p in BleFragCodec.fragment(kBleChNoti, m2, 2)) {
        final g = r.add(p);
        if (g != null) results.add(g);
      }

      expect(results.length, 2);
      expect(results[0].$1, kBleChData);
      expect(results[0].$2, m1);
      expect(results[1].$1, kBleChNoti);
      expect(results[1].$2, m2);
    });
  });

  group('reassembler robustness', () {
    test('short packet (< header) is dropped', () {
      expect(BleReassembler().add(const [0xAA]), isNull);
    });

    test('fragment with no preceding FIRST is dropped', () {
      final r = BleReassembler();
      // A middle/last fragment without FIRST: flags = LAST only.
      expect(r.add([5, kBleFlagLast, 1, 2, 3]), isNull);
    });

    test('new FIRST resets a half-received message', () {
      final r = BleReassembler();
      final full = BleFragCodec.fragment(kBleChData, _seq(400), 0);
      r.add(full[0]); // FIRST, not LAST — buffer now half full
      // Restart with a fresh single-packet message.
      final fresh = BleFragCodec.fragment(kBleChData, _seq(10), 9);
      final out = r.add(fresh[0]);
      expect(out, isNotNull);
      expect(out!.$2, _seq(10));
    });
  });
}
