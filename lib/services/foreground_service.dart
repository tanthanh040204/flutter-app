/*
 * @file       foreground_service.dart
 * @brief      Android/iOS foreground service wrapper that keeps the app
 *             process (and its MQTT connection) alive while a rental is
 *             active, so warnings / END_RENTAL are not missed in background.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/* Constants ---------------------------------------------------------- */
const String _kChannelId = 'ute_go_rental';
const String _kChannelName = 'Active rental';

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */
/* Public classes ----------------------------------------------------- */

/* Static facade — no instance state beyond the one-time init guard. */
class RideForegroundService {
  RideForegroundService._();

  static bool _initialized = false;

  /* Android only: iOS has no equivalent long-lived foreground service and
   * would need separate Info.plist background-mode setup. */
  static bool get _supported =>
      defaultTargetPlatform == TargetPlatform.android;

  /* Idempotent. Start the service for an active rental; if already running,
   * just refresh the notification text. */
  static Future<void> start({
    required String title,
    required String text,
  }) async {
    if (!_supported) return;
    _ensureInit();

    final NotificationPermission perm =
        await FlutterForegroundTask.checkNotificationPermission();
    if (perm != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
      );
      return;
    }

    await FlutterForegroundTask.startService(
      serviceTypes: const [ForegroundServiceTypes.dataSync],
      notificationTitle: title,
      notificationText: text,
    );
  }

  static Future<void> stop() async {
    if (!_supported) return;
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  /* --- private methods ----------------------------------------- */
  static void _ensureInit() {
    if (_initialized) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _kChannelId,
        channelName: _kChannelName,
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        /* No periodic isolate work — the service exists only to keep the
         * main isolate (MQTT + countdown) alive in the background. */
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _initialized = true;
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
