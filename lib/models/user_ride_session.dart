class UserRideSession {
  final String sessionId;
  final String uid;
  final String employeeCode;
  final String userName;
  final String vehicleId;
  final String vehicleName;
  final String? stationStartId;
  final String? stationEndId;
  final String status;
  final DateTime startedAt;
  final DateTime? pausedAt;
  final DateTime? endedAt;
  final DateTime lastHeartbeatAt;
  final int pricePerHour;
  final int depositAmount;
  final int mainAmountUsed;
  final int depositUsed;
  final int remainingBalanceSnapshot;
  final int remainingSeconds;
  final bool canUnlock;
  final List<String> routeIds;

  const UserRideSession({
    required this.sessionId,
    required this.uid,
    required this.employeeCode,
    required this.userName,
    required this.vehicleId,
    required this.vehicleName,
    required this.stationStartId,
    required this.stationEndId,
    required this.status,
    required this.startedAt,
    required this.pausedAt,
    required this.endedAt,
    required this.lastHeartbeatAt,
    required this.pricePerHour,
    required this.depositAmount,
    required this.mainAmountUsed,
    required this.depositUsed,
    required this.remainingBalanceSnapshot,
    required this.remainingSeconds,
    required this.canUnlock,
    required this.routeIds,
  });

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isEnded => status == 'ended' || status == 'expired';
}
