/*
 * @file       mqtt_service.dart
 * @brief      Thin wrapper around mqtt_client: connect, publish, and expose
 *             per-topic streams of decoded ProtocolMessage.
 */

/* Imports ------------------------------------------------------------ */
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../config/mqtt_config.dart';
import 'protocol_codec.dart';

/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */

enum AppMqttState { disconnected, connecting, connected, failed }

/* Typedef / Function types ------------------------------------------ */
/* Public classes ----------------------------------------------------- */

class MqttService extends ChangeNotifier {
  MqttService();

  /* --- private fields ------------------------------------------ */
  MqttServerClient? _client;
  AppMqttState _state = AppMqttState.disconnected;
  String _clientId = 'user';
  StreamSubscription? _messagesSub;

  final Map<String, StreamController<ProtocolMessage>> _topicCtls = {};
  final Set<String> _subscribedTopics = {};

  /* --- public getters ------------------------------------------ */
  AppMqttState get state => _state;
  bool get isConnected => _state == AppMqttState.connected;

  /* --- public methods ------------------------------------------ */
  Future<bool> connect({required String clientId}) async {
    if (_state == AppMqttState.connecting) {
      debugPrint('[MQTT] skip connect: already connecting, clientId=$_clientId');
      return false;
    }
    if (isConnected && _clientId == clientId) {
      debugPrint('[MQTT] skip connect: already connected, clientId=$clientId');
      return true;
    }

    _clientId = clientId;
    _state = AppMqttState.connecting;
    debugPrint('[MQTT] connecting - clientId: $clientId');
    notifyListeners();

    final MqttServerClient client = MqttServerClient.withPort(
      kMqttBrokerHost,
      clientId,
      kMqttBrokerPort,
    );
    client.secure = kMqttUseTls;
    client.keepAlivePeriod = kMqttKeepAliveSec;
    client.autoReconnect = true;
    client.logging(on: false);
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = (_) {};
    client.onAutoReconnect = () {};
    client.onAutoReconnected = _onAutoReconnected;

    final MqttConnectMessage connMsg = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    client.connectionMessage = connMsg;

    try {
      if (kMqttBrokerUsername.isNotEmpty) {
        await client.connect(kMqttBrokerUsername, kMqttBrokerPassword);
      } else {
        await client.connect();
      }
    } catch (e) {
      debugPrint('[MQTT] exception while connecting - clientId: $clientId, error: $e');
      client.disconnect();
      _state = AppMqttState.failed;
      notifyListeners();
      return false;
    }

    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint(
        '[MQTT] connection failed - status: ${client.connectionStatus}',
      );
      client.disconnect();
      _state = AppMqttState.failed;
      notifyListeners();
      return false;
    }

    _client = client;
    _state = AppMqttState.connected;
    debugPrint('[MQTT] connected - clientId: $clientId');

    _messagesSub = client.updates?.listen(_onIncomingMessages);

    /* Re-subscribe any topics that were added before the connection was up. */
    for (final String topic in _subscribedTopics) {
      debugPrint('[MQTT] re-subscribe after connect - topic: $topic');
      client.subscribe(topic, MqttQos.atLeastOnce);
    }

    notifyListeners();
    return true;
  }

  Future<void> disconnect() async {
    debugPrint('[MQTT] disconnect requested - clientId: $_clientId');
    _messagesSub?.cancel();
    _messagesSub = null;
    _client?.disconnect();
    _client = null;
    _state = AppMqttState.disconnected;
    notifyListeners();
  }

  /*
   * Returns a broadcast stream of decoded messages for the given topic.
   * The first call for a topic subscribes on the broker; later calls reuse
   * the same controller.
   */
  Stream<ProtocolMessage> streamOf(String topic) {
    final StreamController<ProtocolMessage> ctl = _topicCtls.putIfAbsent(
      topic,
      () => StreamController<ProtocolMessage>.broadcast(),
    );
    if (!_subscribedTopics.contains(topic)) {
      _subscribedTopics.add(topic);
      debugPrint('[MQTT] register stream - topic: $topic, connected=$isConnected');
      if (isConnected) {
        debugPrint('[MQTT] subscribe - topic: $topic');
        _client!.subscribe(topic, MqttQos.atLeastOnce);
      }
    }
    return ctl.stream;
  }

  void unsubscribe(String topic) {
    if (!_subscribedTopics.remove(topic)) return;
    if (isConnected) {
      debugPrint('[MQTT] unsubscribe - topic: $topic');
      _client!.unsubscribe(topic);
    }
    _topicCtls.remove(topic)?.close();
  }

  bool publish(String topic, String payload) {
    if (!isConnected) {
      debugPrint('[MQTT] publish failed (not connected) - topic: $topic payload: $payload');
      return false;
    }
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    debugPrint('[MQTT] publish - topic: $topic payload: $payload');
    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    return true;
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    for (final StreamController<ProtocolMessage> ctl in _topicCtls.values) {
      ctl.close();
    }
    _topicCtls.clear();
    _client?.disconnect();
    super.dispose();
  }

  /* --- private methods ----------------------------------------- */
  void _onConnected() {
    debugPrint('[MQTT] callback onConnected - clientId: $_clientId');
    _state = AppMqttState.connected;
    notifyListeners();
  }

  void _onDisconnected() {
    debugPrint('[MQTT] callback onDisconnected - clientId: $_clientId');
    _state = AppMqttState.disconnected;
    notifyListeners();
  }

  void _onAutoReconnected() {
    debugPrint('[MQTT] callback onAutoReconnected - clientId: $_clientId');
    for (final String topic in _subscribedTopics) {
      debugPrint('[MQTT] auto re-subscribe - topic: $topic');
      _client?.subscribe(topic, MqttQos.atLeastOnce);
    }
  }

  void _onIncomingMessages(List<MqttReceivedMessage<MqttMessage>> events) {
    for (final MqttReceivedMessage<MqttMessage> event in events) {
      final MqttPublishMessage msg = event.payload as MqttPublishMessage;
      final String payload = MqttPublishPayload.bytesToStringAsString(
        msg.payload.message,
      );
      debugPrint('[MQTT] incoming - topic: ${event.topic} payload: $payload');
      final ProtocolMessage decoded = ProtocolCodec.parse(payload);
      _topicCtls[event.topic]?.add(decoded);
    }
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
