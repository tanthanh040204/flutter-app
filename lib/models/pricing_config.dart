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
