/*
 * @file       feature_conf.dart
 * @brief      Compile-time feature flags and tunables. Single source of truth
 *             for behaviour toggles; mirrors flutter-web/lib/config/feature_config.dart.
 */

/* Imports ------------------------------------------------------------ */
/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class FeatureConfig {
  FeatureConfig._();

  /* --- Backend toggles ----------------------------------------- */
  static const bool enableMqtt = true;
  static const bool enableFirebase = true;
  static const bool enableNotifications = true;

  /* --- Debug toggles ------------------------------------------- */
  static const bool enableDebugAddToken = false;
  static const bool debugMqttLog = true;
  static const bool debugTelemetryLog = true;
  static const bool debugRideLog = true;
  static const bool debugWalletLog = true;

  /* --- Rental tunables ----------------------------------------- */
  static const int rentalPauseTimeoutSeconds = 3600;
  static const int rentalPausePriceFactorPercent = 50;
  static const int rentalRemainingSecondsMax = 999999;

  /* --- Wallet tunables ----------------------------------------- */
  static const int topupResponseTimeoutSeconds = 20;

  /* --- Demo defaults ------------------------------------------- */
  static const String defaultDemoVehicleId = 'V1';
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
