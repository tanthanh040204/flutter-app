import 'package:latlong2/latlong.dart';

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

  String _two(int n) => n.toString().padLeft(2, '0');

  String get buttonLabel {
    final start = '${_two(startAt.hour)}h${_two(startAt.minute)}-${_two(startAt.day)}/${_two(startAt.month)}';
    if (endAt == null) return 'Lộ trình $start';
    final end = '${_two(endAt!.hour)}h${_two(endAt!.minute)}-${_two(endAt!.day)}/${_two(endAt!.month)}';
    return 'Lộ trình $start đến $end';
  }
}
