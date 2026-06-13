/*
 * @file       mobile_notifications_tab.dart
 * @brief      Notifications tab: shows user alerts.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/user_notice.dart';
import '../../providers/mobile_notice_provider.dart';

/* Constants ---------------------------------------------------------- */
const Color kIconColor = Color(0xFF2563EB);
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
                  title: _titleFor(notice, t),
                  body: _bodyFor(notice, t),
                  onDelete: () => provider.deleteNotice(notice.id),
                ),
                const SizedBox(height: 10),
              ],
            ] else
              _EmptyNotifications(title: t.notifications),
          ],
        ),
      ),
    );
  }

  static String _titleFor(UserNotice n, AppStrings t) =>
      n.type == kNoticeTypeStolen ? t.stolenAlertTitle : n.title;

  static String _bodyFor(UserNotice n, AppStrings t) =>
      n.type == kNoticeTypeStolen ? t.stolenAlertBody : n.body;

  static IconData _iconFor(String type) {
    switch (type) {
      case kNoticeTypeBattery:
        return Icons.battery_alert;
      case kNoticeTypeStolen:
        return Icons.gpp_maybe;
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
      case kNoticeTypeStolen:
        return Colors.red;
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
  final VoidCallback onDelete;

  const _NoticeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.onDelete,
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
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.black38),
            onPressed: onDelete,
          ),
        ],
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
