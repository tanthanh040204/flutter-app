/*
 * @file       wallet_topup_request.dart
 * @brief      Data model for a wallet top-up request.
 */

/* Imports ------------------------------------------------------------ */
/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class WalletTopupRequest {
  final String id;
  final String uid;
  final int amount;
  final String transferContent;
  final String status;
  final DateTime createdAt;

  const WalletTopupRequest({
    required this.id,
    required this.uid,
    required this.amount,
    required this.transferContent,
    required this.status,
    required this.createdAt,
  });
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
