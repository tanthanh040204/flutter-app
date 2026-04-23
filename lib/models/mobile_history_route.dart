/*
 * @file       mobile_history_route.dart
 * @brief      Data model representing a recorded ride history route.
 */

/* Imports ------------------------------------------------------------ */
import 'package:latlong2/latlong.dart';

/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class MobileHistoryRoute {
  final String id;
  final String vehicleId;
  final DateTime startAt;
  final DateTime? endAt;
  final List<LatLng> points;

  const MobileHistoryRoute({
    required this.id,
    required this.vehicleId,
    required this.startAt,
    required this.endAt,
    required this.points,
  });

  String get buttonLabel {
    final String start =
        '${_two(startAt.hour)}h${_two(startAt.minute)}'
        '-${_two(startAt.day)}/${_two(startAt.month)}';
    if (endAt == null) return 'Lộ trình $start';
    final String end =
        '${_two(endAt!.hour)}h${_two(endAt!.minute)}'
        '-${_two(endAt!.day)}/${_two(endAt!.month)}';
    return 'Lộ trình $start đến $end';
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
