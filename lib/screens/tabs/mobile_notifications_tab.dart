import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/mobile_notice_provider.dart';
import '../route_view_screen.dart';

class MobileNotificationsTab extends StatelessWidget {
  const MobileNotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MobileNoticeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...provider.notices.map(
            (notice) => Card(
              child: ListTile(
                title: Text(notice.title),
                subtitle: Text(notice.body),
                leading: Icon(_iconFor(notice.type), color: const Color(0xFF1557FF)),
              ),
            ),
          ),
          if (provider.routes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Lộ trình', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...provider.routes.map(
              (route) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RouteViewScreen(route: route),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(route.buttonLabel),
                  ),
                ),
              ),
            )
          ]
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'battery_low':
        return Icons.battery_alert;
      case 'ride_status':
      case 'ride_paused':
      case 'ride_ended':
        return Icons.electric_bike;
      default:
        return Icons.notifications;
    }
  }
}
