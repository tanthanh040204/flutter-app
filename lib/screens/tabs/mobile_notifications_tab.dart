import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../providers/mobile_notice_provider.dart';
import '../../widgets/extend_ride_sheet.dart';
import '../route_view_screen.dart';

class MobileNotificationsTab extends StatelessWidget {
  const MobileNotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tr;
    final provider = context.watch<MobileNoticeProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(t.notifications)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...provider.notices.map(
            (notice) => Card(
              child: ListTile(
                title: Text(notice.title),
                subtitle: Text(notice.body),
                leading: Icon(
                  _iconFor(notice.type),
                  color: const Color(0xFF1557FF),
                ),
                trailing: notice.type == 'ride_15m_warning'
                    ? const Icon(Icons.chevron_right)
                    : null,
                onTap: notice.type == 'ride_15m_warning'
                    ? () => showExtendRideSheet(context)
                    : null,
              ),
            ),
          ),
          if (provider.routes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              t.routes,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
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
      case 'ride_15m_warning':
        return Icons.more_time;
      case 'ride_return_station':
        return Icons.warning_amber_rounded;
      case 'ride_status':
      case 'ride_paused':
      case 'ride_extended':
      case 'ride_ended':
        return Icons.electric_bike;
      default:
        return Icons.notifications;
    }
  }
}
