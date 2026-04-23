/*
 * @file       mqtt_config.dart
 * @brief      MQTT broker configuration and topic name builders.
 */

/* Imports ------------------------------------------------------------ */
/* Constants ---------------------------------------------------------- */

/* --- Broker settings --------------------------------------------- */
const String kMqttBrokerHost = 'broker.emqx.io';
/* MqttServerClient uses native MQTT/TCP, not websocket. */
const int kMqttBrokerPort = 1883;
const String kMqttBrokerUsername = '';
const String kMqttBrokerPassword = '';
const bool kMqttUseTls = false;
const int kMqttKeepAliveSec = 30;

/* --- Special topics --------------------------------------------- */
const String kTopicAddTokenRequest = 'Q7M4K2P/request';

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */

/*
 * Builds MQTT topic names following the spec:
 *   bike_id/app_web   App -> Web
 *   bike_id/web_app   Web -> App
 *   bike_id/cmd       Web -> Device
 *   bike_id/noti      Device -> Web
 *   bike_id/data      Device -> App (telemetry)
 *   {user_id}/response Web -> App (wallet responses)
 */
class MqttTopics {
  MqttTopics._();

  static String appToWeb(String bikeId) => '$bikeId/app_web';
  static String webToApp(String bikeId) => '$bikeId/web_app';
  static String deviceData(String bikeId) => '$bikeId/data';
  static String userResponse(String userId) => '$userId/response';
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
