/*
 * @file       pricing_screen.dart
 * @brief      Displays current pricing and limits to the end-user.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pricing_config.dart';
import '../providers/mobile_ride_provider.dart';

/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PricingConfig pricing = context.watch<MobileRideProvider>().pricing;
    return Scaffold(
      appBar: AppBar(title: const Text('Pricing')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Rate per hour'),
              trailing: Text('${pricing.pricePerHour}đ'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Deposit'),
              trailing: Text('${pricing.depositAmount}đ'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Minimum balance to start'),
              trailing: Text('${pricing.minimumRequiredBalance}đ'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Suggested return battery threshold'),
              trailing: Text('${pricing.lowBatteryThreshold}%'),
            ),
          ),
        ],
      ),
    );
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
