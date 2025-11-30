import 'dart:async';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import '../models/sensor_data.dart';

class MQTTService {
  late MqttBrowserClient client;

  static const String host = '92f3c5f778a8493db77b4b9500dd459c.s1.eu.hivemq.cloud';
  static const int websocketPort = 8884;
  static const String websocketPath = '/mqtt';
  static const String username = 'piquet';
  static const String password = 'Piquet123*';

  Function(SensorData)? onDataReceived;

  final _connectionStateController =
      StreamController<MqttConnectionState>.broadcast();

  Stream<MqttConnectionState> get connectionState =>
      _connectionStateController.stream;

  Future<void> connect() async {
    try {
      final clientId = 'flutter_web_${DateTime.now().millisecondsSinceEpoch}';
      final url = 'wss://$host$websocketPath';

      client = MqttBrowserClient(url, clientId)
        ..port = websocketPort
        ..websocketProtocols = ['mqtt']
        ..logging(on: false);

      await client.connect(username, password);

      final state = client.connectionStatus?.state ??
          MqttConnectionState.disconnected;

      _connectionStateController.add(state);

      if (state == MqttConnectionState.connected) {
        _subscribeToTopics();
        _listenToMessages();
      }
    } catch (e) {
      print('MQTT web error: $e');
      _connectionStateController.add(MqttConnectionState.disconnected);
    }
  }

  void _subscribeToTopics() {
    final topics = [
      'farm/soil1',
      'farm/soil2',
      'farm/soil3',
      'farm/soil4',
      'piquet/agricole/capteurs/+/data',
    ];

    for (final topic in topics) {
      client.subscribe(topic, MqttQos.atLeastOnce);
    }
  }

  void _listenToMessages() {
    client.updates?.listen((messages) {
      for (final message in messages) {
        final payload = message.payload as MqttPublishMessage;
        final msg = MqttPublishPayload.bytesToStringAsString(payload.payload.message);
        final data = SensorData.fromMqtt(message.topic, msg);
        onDataReceived?.call(data);
      }
    });
  }

  void disconnect() => client.disconnect();
  void dispose() => _connectionStateController.close();
}
