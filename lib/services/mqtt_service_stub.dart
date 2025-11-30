import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import '../models/sensor_data.dart';

class MQTTService {
  Function(SensorData)? onDataReceived;

  final _connectionStateController =
      StreamController<MqttConnectionState>.broadcast();

  Stream<MqttConnectionState> get connectionState =>
      _connectionStateController.stream;

  Future<void> connect() async {
    throw UnsupportedError("MQTT not supported on this platform");
  }

  void publish(String topic, String message) {}
  void subscribe(String topic) {}
  void disconnect() {}
  void dispose() => _connectionStateController.close();
}
