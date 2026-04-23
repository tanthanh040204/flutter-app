/*
 * @file       protocol_codec.dart
 * @brief      Encodes and decodes the "CMD=arg1,arg2" text protocol that the
 *             App exchanges with the Web backend over MQTT.
 */

/* Imports ------------------------------------------------------------ */
/* Constants ---------------------------------------------------------- */

/* --- App -> Web commands ---------------------------------------- */
const String kCmdStartRental = 'START_RENTAL';
const String kCmdStopRental  = 'STOP_RENTAL';
const String kCmdPause       = 'PAUSE';
const String kCmdResume      = 'RESUME';
const String kCmdReqAddToken = 'REQ_ADD_TOKEN';

/* --- Web -> App events ------------------------------------------ */
const String kEvtStartRentalSuccess  = 'START_RENTAL_SUCCESS';
const String kEvtStopRentalFail      = 'STOP_RENTAL_FAIL';
const String kEvtPauseSuccess        = 'PAUSE_SUCCESS';
const String kEvtResumeSuccess       = 'RESUME_SUCCESS';
const String kEvtEndRental           = 'END_RENTAL';
const String kEvtRentalErr           = 'RENTAL_ERR';
const String kEvtWarnLowBalance      = 'WARN_LOW_BALANCE';
const String kEvtWarnOutOfBalance    = 'WARN_OUT_OF_BALANCE';
const String kEvtRespAddTokenSuccess = 'RESP_ADD_TOKEN_SUCCESS';
const String kEvtRespAddTokenError   = 'RESP_ADD_TOKEN_ERROR';

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */

class ProtocolMessage {
  final String       command;
  final List<String> args;

  const ProtocolMessage({required this.command, required this.args});

  String? argAt(int i) => (i < args.length) ? args[i] : null;

  @override
  String toString() => 'ProtocolMessage($command, $args)';
}

class ProtocolCodec {
  ProtocolCodec._();

  static String build(String command, [List<String> args = const []]) {
    if (args.isEmpty) return command;
    return '$command=${args.join(',')}';
  }

  static ProtocolMessage parse(String raw) {
    final String payload = raw.trim();
    final int    eqIdx   = payload.indexOf('=');
    if (eqIdx < 0) {
      return ProtocolMessage(command: payload, args: const []);
    }
    final String       cmd     = payload.substring(0, eqIdx);
    final String       argPart = payload.substring(eqIdx + 1);
    final List<String> args    = argPart
        .split(',')
        .map((e) => e.trim())
        .toList();
    return ProtocolMessage(command: cmd, args: args);
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
