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

  /// Thời điểm bắt đầu đếm thời gian của lượt chạy hiện tại.
  /// Khi tạm ngưng thì field này null, app giữ nguyên remainingSeconds.
  final DateTime? runningSince;

  /// Đánh dấu đã tạo thông báo còn 15 phút để tránh báo lặp liên tục.
  final DateTime? warn15mSentAt;

  /// Đánh dấu thời điểm hết giờ nhưng xe vẫn chưa khóa.
  final DateTime? expiredAt;

  /// Mốc tiếp theo backend/bridge được phép trừ phí quá giờ.
  final DateTime? nextPenaltyAt;

  final int pricePerHour;
  final int depositAmount;
  final int mainAmountUsed;
  final int depositUsed;
  final int remainingBalanceSnapshot;
  final int remainingSeconds;
  final int extendedSecondsTotal;
  final int overtimePenaltyCount;
  final int overtimePenaltyAmount;
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
    required this.runningSince,
    required this.warn15mSentAt,
    required this.expiredAt,
    required this.nextPenaltyAt,
    required this.pricePerHour,
    required this.depositAmount,
    required this.mainAmountUsed,
    required this.depositUsed,
    required this.remainingBalanceSnapshot,
    required this.remainingSeconds,
    required this.extendedSecondsTotal,
    required this.overtimePenaltyCount,
    required this.overtimePenaltyAmount,
    required this.canUnlock,
    required this.routeIds,
  });

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isEnded => status == 'ended' || status == 'expired';
}
