/*
 * @file       app_mode.dart
 * @brief      Runtime backend mode (Online / Local) chosen on the first screen.
 *             Persisted so the choice survives restarts; read synchronously by
 *             MobileUserRepo._useLocalDemo to route reads/writes.
 */

/* Imports ------------------------------------------------------------ */
import 'package:shared_preferences/shared_preferences.dart';

/* Constants ---------------------------------------------------------- */
const String _kForceLocalKey = 'app_force_local_mode';

/* Public classes ----------------------------------------------------- */
class AppMode {
  AppMode._();

  // When true, the app ignores Firestore/Auth and runs on the in-memory
  // local/demo backend — used as a fallback when the cloud is unavailable
  // (e.g. Firestore quota exhausted). Mirrors flutter-web's forceLocalMode.
  static bool forceLocal = false;

  // Load the persisted choice. Call once in main() before runApp so the first
  // _useLocalDemo read sees the right value.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      forceLocal = prefs.getBool(_kForceLocalKey) ?? false;
    } catch (_) {
      forceLocal = false;
    }
  }

  // Update the choice in memory and persist it.
  static Future<void> setForceLocal(bool value) async {
    forceLocal = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kForceLocalKey, value);
    } catch (_) {
      /* Best-effort persistence; the in-memory value still applies. */
    }
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
