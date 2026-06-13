/*
 * @file       ride_snapshot.dart
 * @brief      Minimal persisted snapshot of an in-flight rental, used to
 *             restore MobileRideProvider state across app restart / re-login.
 */

/* Imports ------------------------------------------------------------ */
/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */
/* Public classes ----------------------------------------------------- */

class RideSnapshot {
  final String wireUserId;
  final String bikeId;
  /* 'active' (running) or 'paused' — matches kStatusActive / kStatusPaused. */
  final String status;
  final int selectedRentalHours;
  /* Wall-clock start of the CURRENT phase, paired with consumedAtPhaseStart
   * so the live countdown can be reconstructed after a cold start. */
  final DateTime phaseStartedAt;
  final int consumedAtPhaseStart;

  const RideSnapshot({
    required this.wireUserId,
    required this.bikeId,
    required this.status,
    required this.selectedRentalHours,
    required this.phaseStartedAt,
    required this.consumedAtPhaseStart,
  });

  Map<String, dynamic> toMap() => {
    'wireUserId': wireUserId,
    'bikeId': bikeId,
    'status': status,
    'selectedRentalHours': selectedRentalHours,
    'phaseStartedAtMs': phaseStartedAt.millisecondsSinceEpoch,
    'consumedAtPhaseStart': consumedAtPhaseStart,
  };

  static RideSnapshot? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    final String bikeId = (m['bikeId'] ?? '').toString();
    if (bikeId.isEmpty) return null;
    return RideSnapshot(
      wireUserId: (m['wireUserId'] ?? '').toString(),
      bikeId: bikeId,
      status: (m['status'] ?? '').toString(),
      selectedRentalHours: (m['selectedRentalHours'] as num?)?.toInt() ?? 1,
      phaseStartedAt: DateTime.fromMillisecondsSinceEpoch(
        (m['phaseStartedAtMs'] as num?)?.toInt() ?? 0,
      ),
      consumedAtPhaseStart: (m['consumedAtPhaseStart'] as num?)?.toInt() ?? 0,
    );
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
