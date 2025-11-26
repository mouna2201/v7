class MqttService {
  Future<void> connect() async {
    throw UnsupportedError("MQTT not supported on this platform");
  }

  void publish(String topic, String message) {}
  void subscribe(String topic) {}
}
