/*
 * @file       mobile_notifications_tab.dart
 * @brief      Notifications tab: shows user alerts and history routes.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/mobile_history_route.dart';
import '../../providers/mobile_notice_provider.dart';
import '../route_view_screen.dart';

/* Constants ---------------------------------------------------------- */
const Color kIconColor = Color(0xFF2563EB);
const Color kRouteColor = Color(0xFF0F766E);
const String kNoticeTypeBattery = 'battery_low';
const String kNoticeTypeStatus = 'ride_status';
const String kNoticeTypePaused = 'ride_paused';
const String kNoticeTypeEnded = 'ride_ended';

/* Public classes ----------------------------------------------------- */
class MobileNotificationsTab extends StatelessWidget {
  const MobileNotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStrings t = context.tr;
    final MobileNoticeProvider provider = context.watch<MobileNoticeProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(t.notifications)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC), Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (provider.notices.isNotEmpty) ...[
              for (final notice in provider.notices) ...[
                _NoticeCard(
                  icon: _iconFor(notice.type),
                  color: _colorFor(notice.type),
                  title: notice.title,
                  body: notice.body,
                ),
                const SizedBox(height: 10),
              ],
            ] else
              _EmptyNotifications(title: t.notifications),
            if (provider.routes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.route_outlined, color: kRouteColor),
                  const SizedBox(width: 8),
                  Text(
                    t.routes,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final route in provider.routes) ...[
                _RouteCard(
                  title: _routeButtonLabel(route, t),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RouteViewScreen(route: route),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }

  static String _routeButtonLabel(MobileHistoryRoute route, AppStrings t) {
    final String start =
        '${_two(route.startAt.hour)}:${_two(route.startAt.minute)}'
        ' ${_two(route.startAt.day)}/${_two(route.startAt.month)}';
    if (route.endAt == null) return t.routeAt(start);
    final String end =
        '${_two(route.endAt!.hour)}:${_two(route.endAt!.minute)}'
        ' ${_two(route.endAt!.day)}/${_two(route.endAt!.month)}';
    return t.routeFromTo(start, end);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static IconData _iconFor(String type) {
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

  static Color _colorFor(String type) {
    switch (type) {
      case kNoticeTypeBattery:
        return Colors.orange;
      case kNoticeTypeEnded:
        return Colors.green;
      case kNoticeTypePaused:
        return Colors.purple;
      default:
        return kIconColor;
    }
  }
}

class _NoticeCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _NoticeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(body, style: const TextStyle(color: Colors.black54, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _RouteCard({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: kRouteColor.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kRouteColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.alt_route, color: kRouteColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  final String title;

  const _EmptyNotifications({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kIconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.notifications_none, color: kIconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

/* End of file -------------------------------------------------------- */
