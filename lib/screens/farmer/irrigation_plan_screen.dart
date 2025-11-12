import 'package:flutter/material.dart';
import 'dart:math';
import '../../services/mqtt_service.dart';
import '../../models/sensor_data.dart';
import '../../theme/app_theme.dart';

class IrrigationPlanScreen extends StatefulWidget {
  final String location;
  final String soilType;
  final List<String> cropTypes;

  const IrrigationPlanScreen({
    super.key,
    required this.location,
    required this.soilType,
    required this.cropTypes,
  });

  @override
  State<IrrigationPlanScreen> createState() => _IrrigationPlanScreenState();
}

class _IrrigationPlanScreenState extends State<IrrigationPlanScreen> {
  final MQTTService _mqttService = MQTTService();
  SensorData? _latestSensorData;
  final List<SensorData> _sensorHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeMQTT();
  }

  @override
  void dispose() {
    _mqttService.dispose();
    super.dispose();
  }

  Future<void> _initializeMQTT() async {
    _mqttService.onDataReceived = (SensorData data) {
      print(
        'IrrigationScreen: Données reçues - Topic: ${data.topic}, SoilMoisture: ${data.soilMoisture}',
      );
      setState(() {
        _latestSensorData = data;
        _sensorHistory.add(data);
        if (_sensorHistory.length > 50) {
          _sensorHistory.removeAt(0);
        }
      });
    };
    await _mqttService.connect();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.farmerTheme,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            "Plan d'arrosage - ${widget.location}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: widget.cropTypes.map((crop) {
              return _buildCropCard(crop);
            }).toList(),
          ),
        ),
      ),
    );
  }

  // 🪴 Carte pour chaque culture
  Widget _buildCropCard(String crop) {
    // 🌦️ Données météo simulées
    final weatherData = _generateWeatherData();

    // 🌡️ Humidité du sol depuis MQTT ou valeur par défaut (0 si cloud vide)
    int soilHumidity = _latestSensorData?.soilMoisture?.toInt() ?? 0;

    print(
      'BuildCropCard - LatestSensorData: ${_latestSensorData != null ? "Topic: ${_latestSensorData!.topic}, Soil: ${_latestSensorData!.soilMoisture}" : "null"}',
    );
    print('BuildCropCard - soilHumidity utilisé: $soilHumidity');

    // 💧 Conseil IA
    String recommendation = _getRecommendation(
      widget.soilType,
      crop,
      weatherData,
      soilHumidity,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "Agriculture - $crop",
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              "Sol : ${widget.soilType}",
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          const SizedBox(height: 15),

          // 🔹 Tableau météo
          Column(
            children: weatherData.map((day) {
              final int rainValue = day["rain"] as int;
              bool isRain = rainValue > 40;
              IconData icon = isRain ? Icons.cloud : Icons.wb_sunny;
              Color iconColor = isRain ? Colors.blueAccent : Colors.amberAccent;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      day["day"] as String,
                      style: const TextStyle(color: Colors.white),
                    ),
                    Row(
                      children: [
                        Icon(icon, color: iconColor, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          "$rainValue%",
                          style: const TextStyle(color: Colors.blueAccent),
                        ),
                      ],
                    ),
                    Text(
                      "${day["temp"]} / ${day["min"]}",
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // 🗓️ Mini calendrier d’arrosage intelligent
          _buildWateringCalendar(weatherData, crop),

          const SizedBox(height: 15),

          // 💬 Texte explicatif
          _buildWateringExplanation(crop),

          const SizedBox(height: 20),

          // 🌡️ Niveau d’humidité du sol depuis MQTT
          _buildSoilHumidityWidget(soilHumidity),

          const SizedBox(height: 10),

          // 📊 Source des données
          _buildDataSourceWidget(),

          const SizedBox(height: 20),

          // 🤖 Recommandation IA
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Text(
              "Conseil IA pour $crop :\n$recommendation",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🌾 Widget humidité du sol
  Widget _buildSoilHumidityWidget(int humidity) {
    Color barColor;
    String status;
    IconData icon;

    if (humidity < 30) {
      barColor = Colors.redAccent;
      status = "Sol sec";
      icon = Icons.warning;
    } else if (humidity < 60) {
      barColor = Colors.orangeAccent;
      status = "Humidité moyenne";
      icon = Icons.water_drop;
    } else {
      barColor = Colors.greenAccent;
      status = "Sol humide";
      icon = Icons.eco;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Humidité du sol",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, color: barColor, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: humidity / 100,
                color: barColor,
                backgroundColor: Colors.white24,
                minHeight: 10,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "$humidity%",
              style: const TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(status, style: TextStyle(color: barColor, fontSize: 13)),
      ],
    );
  }

  // 🗓️ Calendrier d’arrosage (IA + météo)
  Widget _buildWateringCalendar(
    List<Map<String, dynamic>> weatherData,
    String crop,
  ) {
    int wateringInterval = 2; // par défaut tous les 2 jours

    if (crop.toLowerCase().contains("olive")) {
      wateringInterval = 7; // 1 fois/semaine
    } else if (crop.toLowerCase().contains("blé")) {
      wateringInterval = 1; // chaque jour
    } else if (crop.toLowerCase().contains("tomate")) {
      wateringInterval = 2; // tous les 2 jours
    } else if (crop.toLowerCase().contains("fraise")) {
      wateringInterval = 1; // chaque jour
    } else if (crop.toLowerCase().contains("maïs")) {
      wateringInterval = 3; // tous les 3 jours
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Calendrier d’arrosage (IA + météo)",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weatherData.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            final int rainValue = day["rain"] as int;
            bool isRain = rainValue > 40;

            bool shouldWater = false;
            if (!isRain) {
              if (wateringInterval == 1) {
                shouldWater = true; // chaque jour
              } else if (index % wateringInterval == 0) {
                shouldWater = true; // selon la fréquence
              }
            }

            return Column(
              children: [
                Text(
                  (day["day"] as String).substring(0, 3),
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Icon(
                  shouldWater ? Icons.water_drop : Icons.cloud,
                  color: shouldWater ? Colors.cyanAccent : Colors.blueAccent,
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  shouldWater ? "Arrose" : "Repos",
                  style: TextStyle(
                    color: shouldWater ? Colors.cyanAccent : Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // 🌦️ Générer les données météo simulées
  List<Map<String, dynamic>> _generateWeatherData() {
    final random = Random();
    return [
      {"day": "Lundi", "temp": "22°", "min": "15°", "rain": random.nextInt(60)},
      {"day": "Mardi", "temp": "24°", "min": "16°", "rain": random.nextInt(60)},
      {
        "day": "Mercredi",
        "temp": "25°",
        "min": "17°",
        "rain": random.nextInt(60),
      },
      {"day": "Jeudi", "temp": "23°", "min": "15°", "rain": random.nextInt(60)},
      {
        "day": "Vendredi",
        "temp": "21°",
        "min": "14°",
        "rain": random.nextInt(60),
      },
      {
        "day": "Samedi",
        "temp": "22°",
        "min": "15°",
        "rain": random.nextInt(60),
      },
      {
        "day": "Dimanche",
        "temp": "24°",
        "min": "16°",
        "rain": random.nextInt(60),
      },
    ];
  }

  // 📊 Widget pour afficher la source des données
  Widget _buildDataSourceWidget() {
    final isUsingMQTTData = _latestSensorData != null;
    final lastUpdate = _latestSensorData?.timestamp;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isUsingMQTTData
            ? Colors.blue.withValues(alpha: 0.2)
            : Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isUsingMQTTData ? Icons.cloud_done : Icons.cloud_off,
            color: isUsingMQTTData ? Colors.blueAccent : Colors.orangeAccent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isUsingMQTTData
                  ? "Données capteurs en temps réel${lastUpdate != null ? " (${lastUpdate.hour}:${lastUpdate.minute.toString().padLeft(2, '0')})" : ""}"
                  : "Cloud vide - Utilisation des valeurs par défaut (0%)",
              style: TextStyle(
                color: isUsingMQTTData
                    ? Colors.blueAccent
                    : Colors.orangeAccent,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 💬 Explication du plan d'arrosage
  Widget _buildWateringExplanation(String crop) {
    String text;
    if (crop.toLowerCase().contains("olive")) {
      text =
          "L'olivier nécessite peu d'eau : un arrosage léger par semaine suffit.";
    } else if (crop.toLowerCase().contains("blé")) {
      text = "Le blé préfère un sol toujours humide : arrosez chaque jour.";
    } else if (crop.toLowerCase().contains("tomate")) {
      text =
          "La tomate a besoin d'un arrosage régulier : tous les 2 jours environ.";
    } else if (crop.toLowerCase().contains("fraise")) {
      text =
          "Les fraises nécessitent beaucoup d'eau : arrosez quotidiennement.";
    } else if (crop.toLowerCase().contains("maïs")) {
      text = "Le maïs aime l'humidité : arrosage tous les 3 jours environ.";
    } else {
      text =
          "Arrosage standard : tous les 2 à 3 jours, selon les conditions météo.";
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.black54, fontSize: 13),
    );
  }

  // 💡 Recommandation IA
  String _getRecommendation(
    String soil,
    String crop,
    List<Map<String, dynamic>> data,
    int humidity,
  ) {
    bool hasRain = data.any((day) => (day["rain"] as int) > 40);

    if (hasRain) {
      return "Pas d'arrosage prévu cette semaine, la pluie couvrira les besoins en eau.";
    }

    String solInfo = "";
    switch (soil.toLowerCase()) {
      case "sableux":
        solInfo = "Le sol sableux retient peu l'eau.";
        break;
      case "argileux":
        solInfo = "Le sol argileux garde bien l'humidité.";
        break;
      case "limoneux":
        solInfo = "Le sol limoneux est équilibré et fertile.";
        break;
      default:
        solInfo = "Sol standard.";
    }

    String freq = "";
    String besoin = "";

    if (crop.toLowerCase().contains("tomate")) {
      freq = "Arrosez chaque jour ou un jour sur deux.";
      besoin = "Besoin moyen : 2L/m² par jour.";
    } else if (crop.toLowerCase().contains("blé")) {
      freq = "Arrosez une fois tous les 4 à 5 jours.";
      besoin = "Besoin faible : 1L/m².";
    } else if (crop.toLowerCase().contains("fraise")) {
      freq = "Arrosage quotidien recommandé.";
      besoin = "Besoin élevé : 2.5L/m².";
    } else if (crop.toLowerCase().contains("olive")) {
      freq = "Arrosez légèrement tous les 5 jours.";
      besoin = "Besoin faible : 1.5L/m².";
    } else if (crop.toLowerCase().contains("maïs")) {
      freq = "Arrosez tous les 2 à 3 jours.";
      besoin = "Besoin moyen : 2L/m².";
    } else {
      freq = "Arrosage standard : tous les 2-3 jours.";
      besoin = "2L/m².";
    }

    if (humidity > 75) {
      return "$solInfo Sol bien humide — reportez l'arrosage.\n$freq ($besoin)";
    } else if (humidity < 40) {
      return "$solInfo Sol sec — arrosez dès aujourd'hui.\n$freq ($besoin)";
    } else {
      return "$solInfo Sol modérément humide.\n$freq ($besoin)";
    }
  }
}
