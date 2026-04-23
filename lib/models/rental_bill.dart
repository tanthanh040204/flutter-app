/*
 * @file       rental_bill.dart
 * @brief      Bill returned at the end of a rental session.
 */

/* Imports ------------------------------------------------------------ */
/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class RentalBill {
  final String   userId;
  final int      amount;
  final String   status;
  final DateTime endedAt;

  const RentalBill({
    required this.userId,
    required this.amount,
    required this.status,
    required this.endedAt,
  });
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
