import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/sensor_data.dart';

class MQTTService {
  late MqttClient client;

  static const String host = '92f3c5f778a8493db77b4b9500dd459c.s1.eu.hivemq.cloud';
  static const int port = 8883;
  static const String username = 'piquet';
  static const String password = 'Piquet123*';

  Function(SensorData)? onDataReceived;

  final _connectionStateController = StreamController<MqttConnectionState>.broadcast();

  Stream<MqttConnectionState> get connectionState =>
      _connectionStateController.stream;

  Future<void> connect() async {
    try {
      final clientId = 'flutter_mobile_${DateTime.now().millisecondsSinceEpoch}';

      final serverClient = MqttServerClient(host, clientId)
        ..port = port
        ..secure = true
        ..logging(on: false);

      client = serverClient;

      client.keepAlivePeriod = 20;

      client.onConnected = () =>
          _connectionStateController.add(MqttConnectionState.connected);

      client.onDisconnected = () =>
          _connectionStateController.add(MqttConnectionState.disconnected);

      await client.connect(username, password);

      final state = client.connectionStatus?.state ??
          MqttConnectionState.disconnected;

      _connectionStateController.add(state);

      if (state == MqttConnectionState.connected) {
        _subscribeToTopics();
        _listenToMessages();
      }
    } catch (e) {
      print('MQTT mobile error: $e');
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
      print('Subscribed: $topic');
    }
  }

  void _listenToMessages() {
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final message in messages) {
        final payload = message.payload as MqttPublishMessage;
        final topic = message.topic;
        final msg = MqttPublishPayload.bytesToStringAsString(
          payload.payload.message,
        );

        onDataReceived?.call(SensorData.fromMqtt(topic, msg));
      }
    });
  }

  void disconnect() => client.disconnect();
  void dispose() => _connectionStateController.close();
}
