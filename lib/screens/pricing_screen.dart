import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/mobile_ride_provider.dart';

class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pricing = context.watch<MobileRideProvider>().pricing;
    return Scaffold(
      appBar: AppBar(title: const Text('Bảng giá')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Giá thuê 1 giờ'),
              trailing: Text('${pricing.pricePerHour}đ'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Tiền cọc'),
              trailing: Text('${pricing.depositAmount}đ'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Số dư tối thiểu để bắt đầu'),
              trailing: Text('${pricing.minimumRequiredBalance}đ'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Ngưỡng pin nên trả xe'),
              trailing: Text('${pricing.lowBatteryThreshold}%'),
            ),
          ),
        ],
      ),
    );
  }
}
