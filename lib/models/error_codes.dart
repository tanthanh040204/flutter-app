/*
 * @file       error_codes.dart
 * @brief      Protocol error codes and their human-readable descriptions.
 */

/* Imports ------------------------------------------------------------ */
/* Constants ---------------------------------------------------------- */

const String kErrAccountInvalid = 'ERR_ACCOUNT_INVALID';
const String kErrUserNotFound = 'ERR_USER_NOT_FOUND';
const String kErrAccountDebt = 'ERR_ACCOUNT_DEBT';
const String kErrInsufficientBalance = 'ERR_INSUFFICIENT_BALANCE';
const String kErrBikeUnavailable = 'ERR_BIKE_UNAVAILABLE';
const String kErrBikeInUse = 'ERR_BIKE_IN_USE';
const String kErrTimeLimitWarning = 'ERR_TIME_LIMIT_WARNING';
const String kErrTimeLimitExceeded = 'ERR_TIME_LIMIT_EXCEEDED';
const String kErrOutOfParkingZone = 'ERR_OUT_OF_PARKING_ZONE';
const String kErrTopupAmountInvalid = 'ERR_TOPUP_AMOUNT_INVALID';
const String kErrTopupFailed = 'ERR_TOPUP_FAILED';
const String kErrUnknown = 'ERR_UNKNOWN';

const String kStatusOk = 'OK';

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */
/* Public classes ----------------------------------------------------- */

class ErrorMessages {
  ErrorMessages._();

  static String describe(String code) {
    switch (code) {
      case kErrAccountInvalid:
        return 'Invalid account.';
      case kErrUserNotFound:
        return 'User does not exist.';
      case kErrAccountDebt:
        return 'Account has outstanding fees.';
      case kErrInsufficientBalance:
        return 'Balance is insufficient to rent.';
      case kErrBikeUnavailable:
        return 'Vehicle is not available.';
      case kErrBikeInUse:
        return 'Vehicle is currently in use by another rider.';
      case kErrTimeLimitWarning:
        return 'You are over the allowed time (warning).';
      case kErrTimeLimitExceeded:
        return 'Time limit exceeded — locked and penalised.';
      case kErrOutOfParkingZone:
        return 'Vehicle is outside a valid parking zone.';
      case kErrTopupAmountInvalid:
        return 'Invalid top-up amount.';
      case kErrTopupFailed:
        return 'Top-up failed.';
      default:
        return 'An error occurred ($code).';
    }
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
