// models/sensor_data.dart
import 'dart:convert';

class SensorData {
  // Champs pour l'API REST
  final String? id;
  final String deviceId;
  final double? temperature;
  final double? temperatureSol;
  final double? humidite; // humidité de l'air
  final double? humiditeSol; // humidité du sol
  final double? pression;
  final DateTime timestampMesure;
  final bool isSimulation;

  // Champs additionnels pour la compatibilité MQTT / anciennes vues
  final double? humidity; // alias de humidite
  final double? soilMoisture; // alias de humiditeSol
  final double? battery;
  final DateTime? timestamp; // alias de timestampMesure
  final String? topic;

  SensorData({
    this.id,
    required this.deviceId,
    this.temperature,
    this.temperatureSol,
    this.humidite,
    this.humiditeSol,
    this.pression,
    required this.timestampMesure,
    this.isSimulation = false,
    this.humidity,
    this.soilMoisture,
    this.battery,
    this.timestamp,
    this.topic,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    final ts = json['timestamp_mesure'] != null
        ? DateTime.parse(json['timestamp_mesure'])
        : DateTime.now();

    final airHum = json['humidite']?.toDouble();
    final soilHum = json['humidite_sol']?.toDouble();

    return SensorData(
      id: json['_id'] ?? json['id'],
      deviceId: json['device_id'] ?? '',
      temperature: json['temperature']?.toDouble(),
      temperatureSol: json['temperature_sol']?.toDouble(),
      humidite: airHum,
      humiditeSol: soilHum,
      pression: json['pression']?.toDouble(),
      timestampMesure: ts,
      isSimulation: json['is_simulation'] ?? false,
      // champs alias pour compatibilité
      humidity: airHum,
      soilMoisture: soilHum,
      timestamp: ts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'temperature': temperature,
      'temperature_sol': temperatureSol,
      'humidite': humidite,
      'humidite_sol': humiditeSol,
      'pression': pression,
      'timestamp_mesure': timestampMesure.toIso8601String(),
      'is_simulation': isSimulation,
    };
  }

  /// Constructeur pour les messages MQTT (compatibilité avec l'ancien code)
  factory SensorData.fromMqtt(String topic, String message) {
    final deviceId = _extractDeviceId(topic);
    final now = DateTime.now();

    try {
      final data = json.decode(message);
      final ts = DateTime.parse(
          data['timestamp']?.toString() ?? now.toIso8601String());

      final airHum = (data['humidity'] ?? data['humidite'])?.toDouble();
      final soilHum =
          (data['soil_moisture'] ?? data['farm/soil1'] ?? data['humidite_sol'])
              ?.toDouble();

      return SensorData(
        deviceId: data['device_id'] ?? deviceId,
        temperature: data['temperature']?.toDouble(),
        humidite: airHum,
        humiditeSol: soilHum,
        timestampMesure: ts,
        // alias
        humidity: airHum,
        soilMoisture: soilHum,
        battery: data['battery']?.toDouble(),
        timestamp: ts,
        topic: topic,
      );
    } catch (e) {
      return _parseSimpleMessage(topic, message, now);
    }
  }

  static SensorData _parseSimpleMessage(
      String topic, String message, DateTime timestamp) {
    final deviceId = _extractDeviceId(topic);
    double? temp, airHum, soilHum;

    // Parser température
    final tempMatch =
        RegExp(r'(\d+(?:\.\d+)?)\s*°?\s*[cC]').firstMatch(message);
    if (tempMatch != null) temp = double.parse(tempMatch.group(1)!);

    // Parser humidité
    final humidityMatch = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(message);
    if (humidityMatch != null) airHum = double.parse(humidityMatch.group(1)!);

    // Parser humidité du sol (nombre simple pour les topics farm/soil*)
    if (topic.startsWith('farm/soil1')) {
      try {
        soilHum = double.parse(message.trim());
      } catch (e) {
        final soilMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(message);
        if (soilMatch != null) soilHum = double.parse(soilMatch.group(1)!);
      }
    }

    return SensorData(
      deviceId: deviceId,
      temperature: temp,
      humidite: airHum,
      humiditeSol: soilHum,
      timestampMesure: timestamp,
      // alias
      humidity: airHum,
      soilMoisture: soilHum,
      timestamp: timestamp,
      topic: topic,
    );
  }

  static String _extractDeviceId(String topic) {
    final parts = topic.split('/');
    if (topic.startsWith('farm/')) return parts[1];
    if (topic.contains('capteurs/')) {
      final index = parts.indexOf('capteurs');
      if (index != -1 && index + 1 < parts.length) {
        return parts[index + 1];
      }
    }
    return parts.last;
  }
}
