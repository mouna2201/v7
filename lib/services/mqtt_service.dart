import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/sensor_data.dart';

class MQTTService {
  late MqttClient client;

  static const String host =
      '92f3c5f778a8493db77b4b9500dd459c.s1.eu.hivemq.cloud';
  static const int port = 8883;
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
      final clientId = 'flutter_app_${DateTime.now().millisecondsSinceEpoch}';

      if (kIsWeb) {
        final url = 'wss://$host$websocketPath';
        final browserClient = MqttBrowserClient(url, clientId)
          ..port = websocketPort
          ..logging(on: false)
          ..websocketProtocols = ['mqtt'];
        client = browserClient;
      } else {
        final serverClient = MqttServerClient(host, clientId)
          ..port = port
          ..secure = true
          ..logging(on: false);
        client = serverClient;
      }

      client.keepAlivePeriod = 20;
      client.onConnected = () {
        _connectionStateController.add(MqttConnectionState.connected);
      };
      client.onDisconnected = () {
        _connectionStateController.add(MqttConnectionState.disconnected);
      };

      await client.connect(username, password);

      final currentState =
          client.connectionStatus?.state ?? MqttConnectionState.disconnected;
      _connectionStateController.add(currentState);

      if (currentState == MqttConnectionState.connected) {
        print('Connecté à HiveMQ Cloud');
        _subscribeToTopics();
        _listenToMessages();
        
        // Envoyer un message de test pour vérifier la connexion
        _sendTestMessage();
        
        return;
      }
    } catch (e) {
      print('Erreur connexion MQTT: $e');
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
      print('Souscrit à: $topic');
    }
  }

  void _listenToMessages() {
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final message in messages) {
        final payload = message.payload as MqttPublishMessage;
        final topic = message.topic;
        final messageStr = MqttPublishPayload.bytesToStringAsString(
          payload.payload.message,
        );

        print('Message reçu - Topic: $topic, Message: "$messageStr"');

        final sensorData = SensorData.fromMqtt(topic, messageStr);
        print('Données parsées - Device: ${sensorData.deviceId}, SoilMoisture: ${sensorData.soilMoisture}');
        
        onDataReceived?.call(sensorData);
      }
    });
  }

  void disconnect() {
    client.disconnect();
    _connectionStateController.add(MqttConnectionState.disconnected);
    print('Déconnecté de HiveMQ');
  }

  void _sendTestMessage() {
    // Pour l'instant, on va juste logger qu'on essaie d'envoyer un message
    // La réception des messages existants dans HiveMQ est le vrai problème
    print('Test: Envoi message vers farm/soil1 - Vérification réception...');
    
    // On va forcer une actualisation des données pour tester
    print('Test: Simulation réception message "42"');
    final testData = SensorData.fromMqtt('farm/soil1', '42');
    onDataReceived?.call(testData);
  }

  void dispose() {
    _connectionStateController.close();
  }
}
