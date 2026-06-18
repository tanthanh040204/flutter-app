/*
 * @file       user_notice.dart
 * @brief      Data model for per-user notifications shown in the app.
 */

/* Imports ------------------------------------------------------------ */
/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class UserNotice {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? vehicleId;
  final String? sessionId;
  final String? routeId;
  final bool isRead;
  final DateTime createdAt;

  const UserNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.vehicleId,
    required this.sessionId,
    required this.routeId,
    required this.isRead,
    required this.createdAt,
  });
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
