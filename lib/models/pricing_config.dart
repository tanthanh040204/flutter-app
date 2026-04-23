/*
 * @file       pricing_config.dart
 * @brief      Pricing configuration for ride sessions.
 */

/* Imports ------------------------------------------------------------ */
/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class PricingConfig {
  final int pricePerHour;
  final int depositAmount;
  final int minimumRequiredBalance;
  final int lowBatteryThreshold;

  const PricingConfig({
    required this.pricePerHour,
    required this.depositAmount,
    required this.minimumRequiredBalance,
    required this.lowBatteryThreshold,
  });

  int get totalRequired => pricePerHour + depositAmount;
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
