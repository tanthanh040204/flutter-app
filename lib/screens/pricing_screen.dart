import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/mobile_ride_provider.dart';

class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tr;
    final pricing = context.watch<MobileRideProvider>().pricing;
    return Scaffold(
      appBar: AppBar(title: Text(t.priceList)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(t.pricePerHour),
              trailing: Text('${pricing.pricePerHour}đ'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(t.deposit),
              trailing: Text('${pricing.depositAmount}đ'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(t.minimumBalance),
              trailing: Text('${pricing.minimumRequiredBalance}đ'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(t.lowBatteryReturnThreshold),
              trailing: Text('${pricing.lowBatteryThreshold}%'),
            ),
          ),
        ],
      ),
    );
  }
}
