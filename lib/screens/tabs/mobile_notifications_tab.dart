/*
 * @file       mobile_notifications_tab.dart
 * @brief      Notifications tab: shows user alerts and history routes.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/mobile_notice_provider.dart';
import '../route_view_screen.dart';

/* Constants ---------------------------------------------------------- */
const Color kIconColor = Color(0xFF1557FF);
const String kNoticeTypeBattery = 'battery_low';
const String kNoticeTypeStatus = 'ride_status';
const String kNoticeTypePaused = 'ride_paused';
const String kNoticeTypeEnded = 'ride_ended';

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class MobileNotificationsTab extends StatelessWidget {
  const MobileNotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final MobileNoticeProvider provider = context.watch<MobileNoticeProvider>();

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
                leading: Icon(_iconFor(notice.type), color: kIconColor),
              ),
            ),
          ),
          if (provider.routes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Lộ trình',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case kNoticeTypeBattery:
        return Icons.battery_alert;
      case kNoticeTypeStatus:
      case kNoticeTypePaused:
      case kNoticeTypeEnded:
        return Icons.electric_bike;
      default:
        return Icons.notifications;
    }
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
