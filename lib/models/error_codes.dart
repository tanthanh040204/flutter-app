/*
 * @file       error_codes.dart
 * @brief      Protocol error codes and their Vietnamese descriptions.
 */

/* Imports ------------------------------------------------------------ */
/* Constants ---------------------------------------------------------- */

const String kErrAccountInvalid       = 'ERR_ACCOUNT_INVALID';
const String kErrAccountDebt          = 'ERR_ACCOUNT_DEBT';
const String kErrInsufficientBalance  = 'ERR_INSUFFICIENT_BALANCE';
const String kErrBikeUnavailable      = 'ERR_BIKE_UNAVAILABLE';
const String kErrBikeInUse            = 'ERR_BIKE_IN_USE';
const String kErrTimeLimitWarning     = 'ERR_TIME_LIMIT_WARNING';
const String kErrTimeLimitExceeded    = 'ERR_TIME_LIMIT_EXCEEDED';
const String kErrOutOfParkingZone     = 'ERR_OUT_OF_PARKING_ZONE';
const String kErrTopupAmountInvalid   = 'ERR_TOPUP_AMOUNT_INVALID';
const String kErrTopupFailed          = 'ERR_TOPUP_FAILED';
const String kErrUnknown              = 'ERR_UNKNOWN';

const String kStatusOk = 'OK';

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */
/* Public classes ----------------------------------------------------- */

class ErrorMessages {
  ErrorMessages._();

  static String describe(String code) {
    switch (code) {
      case kErrAccountInvalid:      return 'Tài khoản không hợp lệ.';
      case kErrAccountDebt:         return 'Tài khoản đang nợ cước.';
      case kErrInsufficientBalance: return 'Số dư không đủ để thuê xe.';
      case kErrBikeUnavailable:     return 'Xe không sẵn sàng để thuê.';
      case kErrBikeInUse:           return 'Xe đang được người khác sử dụng.';
      case kErrTimeLimitWarning:    return 'Bạn đã vượt thời gian cho phép (cảnh báo).';
      case kErrTimeLimitExceeded:   return 'Vượt thời gian cho phép — đã bị khóa và phạt.';
      case kErrOutOfParkingZone:    return 'Xe nằm ngoài bãi đỗ hợp lệ.';
      case kErrTopupAmountInvalid:  return 'Số tiền nạp không hợp lệ.';
      case kErrTopupFailed:         return 'Nạp tiền thất bại.';
      default:                      return 'Đã xảy ra lỗi ($code).';
    }
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
