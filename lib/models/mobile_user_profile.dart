class MobileUserProfile {
  final String uid;
  final String employeeCode;
  final String fullName;
  final String? phone;
  final String? email;
  final String role;
  final int balance;
  final int depositLocked;
  final bool isActive;
  final String? currentSessionId;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  /// Dùng cho logic nợ quá giờ và khóa tài khoản sau 2 ngày.
  final DateTime? debtStartedAt;
  final DateTime? debtDueAt;
  final DateTime? blockedAt;
  final String? blockReason;

  const MobileUserProfile({
    required this.uid,
    required this.employeeCode,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.role,
    required this.balance,
    required this.depositLocked,
    required this.isActive,
    required this.currentSessionId,
    required this.createdAt,
    required this.lastLoginAt,
    this.debtStartedAt,
    this.debtDueAt,
    this.blockedAt,
    this.blockReason,
  });

  MobileUserProfile copyWith({
    String? employeeCode,
    String? fullName,
    String? phone,
    String? email,
    String? role,
    int? balance,
    int? depositLocked,
    bool? isActive,
    String? currentSessionId,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? debtStartedAt,
    DateTime? debtDueAt,
    DateTime? blockedAt,
    String? blockReason,
  }) {
    return MobileUserProfile(
      uid: uid,
      employeeCode: employeeCode ?? this.employeeCode,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      balance: balance ?? this.balance,
      depositLocked: depositLocked ?? this.depositLocked,
      isActive: isActive ?? this.isActive,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      debtStartedAt: debtStartedAt ?? this.debtStartedAt,
      debtDueAt: debtDueAt ?? this.debtDueAt,
      blockedAt: blockedAt ?? this.blockedAt,
      blockReason: blockReason ?? this.blockReason,
    );
  }
}
