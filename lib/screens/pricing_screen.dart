/*
 * @file       pricing_screen.dart
 * @brief      Displays current pricing and limits to the end-user.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
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
      appBar: AppBar(title: Text(context.tr.priceList)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(context.tr.ratePerHour),
              trailing: Text('${pricing.pricePerHour}đ'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(context.tr.deposit),
              trailing: Text('${pricing.depositAmount}đ'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(context.tr.minimumRequiredBalance),
              trailing: Text('${pricing.minimumRequiredBalance}đ'),
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
