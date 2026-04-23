/*
 * @file       user_wire_id.dart
 * @brief      Converts app user profile identity into protocol user id:
 *             user_XXXXXXXXXX (10 digits, stable per account).
 */

/* Imports ------------------------------------------------------------ */
/* Constants ---------------------------------------------------------- */
const int kWireUserDigits = 10;
const int kWireUserModulo = 10000000000;

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */
/* Public classes ----------------------------------------------------- */

String buildWireUserId({
  required String uid,
  String? phone,
  String? email,
}) {
  if (uid.startsWith('user_')) {
    final String suffix = uid.substring(5);
    if (_isTenDigits(suffix)) return uid;
  }

  if (_isTenDigits(uid)) return 'user_$uid';

  final String phoneDigits = _digitsOnly(phone ?? '');
  if (phoneDigits.length >= kWireUserDigits) {
    final String tenDigits = phoneDigits.substring(
      phoneDigits.length - kWireUserDigits,
    );
    return 'user_$tenDigits';
  }

  final String seed = '$uid|${email ?? ''}|${phone ?? ''}';
  final int stable = _stableHash31(seed) % kWireUserModulo;
  return 'user_${stable.toString().padLeft(kWireUserDigits, '0')}';
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */

String _digitsOnly(String raw) => raw.replaceAll(RegExp(r'[^0-9]'), '');

bool _isTenDigits(String raw) => RegExp(r'^\d{10}$').hasMatch(raw);

int _stableHash31(String input) {
  int hash = 2166136261;
  for (final int c in input.codeUnits) {
    hash ^= c;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  return hash & 0x7fffffff;
}

/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
