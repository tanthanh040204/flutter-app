/*
 * @file       ble_config.dart
 * @brief      BLE relay constants: Tracker Network Service UUIDs, handshake
 *             magic, fragmentation header layout, channel ids, scan duty-cycle,
 *             and the advertised device-name convention. Mirrors the firmware
 *             side documented in ble_feature.md / new_network.md.
 */

/* Imports ------------------------------------------------------------ */
/* Constants ---------------------------------------------------------- */
const String kBleServiceUuid = 'a0000001-0000-1000-8000-00805f9b34fb';
const String kBleCharData = 'a0000002-0000-1000-8000-00805f9b34fb';
const String kBleCharNoti = 'a0000003-0000-1000-8000-00805f9b34fb';
const String kBleCharCmd = 'a0000004-0000-1000-8000-00805f9b34fb';

const List<int> kBleHandshakeMagic = [0xA5, 0x01];

const int kBleFragMtu = 202;
const int kBleFragMaxPayload = 200;
const int kBleFragHeaderLen = 2;

const int kBleFlagLast = 0x80;
const int kBleFlagFirst = 0x40;
const int kBleChannelMask = 0x3F;

const int kBleChData = 0;
const int kBleChNoti = 1;
const int kBleChCmdResp = 2;

const Duration kBleScanWindow = Duration(seconds: 8);
const Duration kBleScanGap = Duration(seconds: 25);

const String kBlePrefLastBikeId = 'ble_relay_last_bike_id';

const String kBleNamePrefix = 'haq-trk-';

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */
/* Public classes ----------------------------------------------------- */

class BleConfig {
  BleConfig._();

  /* Advertised name convention: haq-trk-<bikeId>. Idempotent — tolerates
   * an id that already carries the prefix (no haq-trk-haq-trk-…). */
  static String deviceName(String bikeId) => bikeId.startsWith(kBleNamePrefix)
      ? bikeId
      : '$kBleNamePrefix$bikeId';
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
