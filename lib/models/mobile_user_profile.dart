/*
 * @file       mobile_user_profile.dart
 * @brief      User profile data model used across the mobile app.
 */

/* Imports ------------------------------------------------------------ */
/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
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
    );
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
