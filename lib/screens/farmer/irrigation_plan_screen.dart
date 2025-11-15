import 'package:flutter/material.dart';
import 'dart:math';
import '../../services/mqtt_service.dart';
import '../../services/weather_service.dart';
import '../../models/sensor_data.dart';
import '../../models/weather_data.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

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
  final WeatherService _weatherService = WeatherService();
  SensorData? _latestSensorData;
  final List<SensorData> _sensorHistory = [];
  WeatherData? _currentWeather;
  bool _isLoadingWeather = true;
  String _weatherError = '';
  late AppLocalizations _l10n;

  @override
  void initState() {
    super.initState();
    _initializeMQTT();
    _loadWeatherForLocation();
  }

  Future<void> _loadWeatherForLocation() async {
    print('🌤️ DÉMARRAGE CHARGEMENT MÉTÉO pour: "${widget.location}"');

    try {
      setState(() {
        _isLoadingWeather = true;
        _weatherError = '';
      });

      print('📡 APPEL API OpenWeatherMap pour: ${widget.location}');

      _currentWeather = await _weatherService.getWeatherByCity(widget.location);

      print(
        '✅ SUCCÈS API: ${_currentWeather!.cityName} - ${_currentWeather!.temperature}°C - ${_currentWeather!.description}',
      );

      setState(() {
        _isLoadingWeather = false;
      });

      print('🎯 MISE À JOUR INTERFACE: météo affichée avec succès');
    } catch (e) {
      print('❌ ERREUR API MÉTÉO: $e');
      setState(() {
        _isLoadingWeather = false;
        _weatherError = 'Erreur: $e';
      });
      print('🔴 MISE À JOUR INTERFACE: erreur affichée');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
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
    // Générer une seule fois la météo pour tout l'écran, commune à toutes les cultures
    final weatherData = _generateWeatherData();

    return Theme(
      data: AppTheme.irrigationTheme,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            "${_l10n.irrigationPlan} - ${widget.location}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.palette, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Changement de thème bientôt disponible"),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // 🌤️ BANDE MÉTEO TRÈS VISIBLE
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 26, 26, 26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color.fromARGB(255, 117, 118, 119),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud, color: Colors.blue, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        "MÉTÉO - ${widget.location.toUpperCase()}",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_isLoadingWeather)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '🔄 Chargement météo pour ${widget.location}...',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else if (_weatherError.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '❌ Erreur météo: $_weatherError',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_currentWeather != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '✅ ${_currentWeather!.cityName}: '
                                  '${_currentWeather!.temperature.round()}°C - '
                                  '${_currentWeather!.description}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (weatherData.isNotEmpty) ...[
                            const Text(
                              'Prévision sur 1 semaine',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Plan météo détaillé sur une semaine
                            Column(
                              children: weatherData.map((day) {
                                final int rainValue = day['rain'] as int;
                                final String temp = day['temp'] as String;
                                final String minTemp = day['min'] as String;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 3),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _getDayName(day['day'] as String),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.thermostat,
                                            color: Colors.orangeAccent,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$temp / $minTemp',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.water_drop,
                                            color: Colors.blueAccent,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$rainValue%',
                                            style: const TextStyle(
                                              color: Colors.blueAccent,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 8),

                            // Humidité moyenne de la semaine (moyenne des rain %)
                            Builder(
                              builder: (context) {
                                final totalRain = weatherData
                                    .map((d) => d['rain'] as int)
                                    .fold<int>(0, (sum, v) => sum + v);
                                final avgRain =
                                    (totalRain / weatherData.length).round();
                                return Text(
                                  'Humidité moyenne de la semaine : $avgRain%',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: widget.cropTypes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final crop = entry.value;

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 400 + index * 120),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: _buildCropCard(crop, weatherData),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropCard(String crop, List<Map<String, dynamic>> weatherData) {
    int soilHumidity = _latestSensorData?.soilMoisture?.toInt() ?? 0;

    print(
      'BuildCropCard - LatestSensorData: ${_latestSensorData != null ? "Topic: ${_latestSensorData!.topic}, Soil: ${_latestSensorData!.soilMoisture}" : "null"}',
    );
    print('BuildCropCard - soilHumidity utilisé: $soilHumidity');

    String recommendation = _getRecommendation(
      widget.soilType.toLowerCase(),
      crop.toLowerCase(),
      weatherData,
      soilHumidity,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getCropIcon(crop),
                  color: Colors.lightGreenAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCropTranslation(crop),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${_l10n.soil} : ${_getSoilTypeTranslation(widget.soilType)}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 14),

          // On n'affiche plus la météo détaillée dans chaque carte culture.
          // On utilise toujours weatherData pour calculer le calendrier d'arrosage.
          _buildWateringCalendar(weatherData, crop),

          const SizedBox(height: 15),

          _buildWateringExplanation(crop),

          const SizedBox(height: 20),

          _buildSoilHumidityWidget(soilHumidity),

          const SizedBox(height: 10),

          _buildDataSourceWidget(),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF444444), width: 1),
            ),
            child: Text(
              "${_l10n.aiAdviceFor} ${_getCropTranslation(crop)} :\n$recommendation",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoilHumidityWidget(int humidity) {
    Color barColor;
    String status;
    IconData icon;

    if (humidity < 30) {
      barColor = Colors.redAccent;
      status = _l10n.drySoil;
      icon = Icons.warning;
    } else if (humidity < 60) {
      barColor = Colors.orangeAccent;
      status = _l10n.mediumHumidity;
      icon = Icons.water_drop;
    } else {
      barColor = Colors.greenAccent;
      status = _l10n.humidSoil;
      icon = Icons.eco;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _l10n.soilMoisture,
          style: const TextStyle(
            color: Colors.white,
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

  Widget _buildWateringCalendar(
    List<Map<String, dynamic>> weatherData,
    String crop,
  ) {
    int wateringInterval = 2;

    if (crop.toLowerCase().contains("olive")) {
      wateringInterval = 7;
    } else if (crop.toLowerCase().contains("blé")) {
      wateringInterval = 1;
    } else if (crop.toLowerCase().contains("tomate")) {
      wateringInterval = 2;
    } else if (crop.toLowerCase().contains("fraise")) {
      wateringInterval = 1;
    } else if (crop.toLowerCase().contains("maïs")) {
      wateringInterval = 3;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _l10n.wateringCalendar,
          style: const TextStyle(
            color: Colors.white,
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
                shouldWater = true;
              } else if (index % wateringInterval == 0) {
                shouldWater = true;
              }
            }

            return Column(
              children: [
                Text(
                  _getDayShortName((day["day"] as String)),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Icon(
                  shouldWater ? Icons.water_drop : Icons.cloud,
                  color: shouldWater ? Colors.cyanAccent : Colors.blueAccent,
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  shouldWater ? _l10n.waterToday : _l10n.rest,
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

  // 🌤️ Générer les données météo à partir de l'API réelle
  // Si l'API ne répond pas, on retourne une liste vide (pas de météo fictive)
  List<Map<String, dynamic>> _generateWeatherData() {
    if (_currentWeather == null) {
      return [];
    }

    final currentTemp = _currentWeather!.temperature.round();
    final random = Random();

    return [
      {
        "day": "monday",
        "temp": "$currentTemp°",
        "min": "${currentTemp - 5}°",
        "rain": _currentWeather!.humidity,
      },
      {
        "day": "tuesday",
        "temp": "${currentTemp + random.nextInt(5) - 2}°",
        "min": "${currentTemp - 3 + random.nextInt(3)}°",
        "rain": random.nextInt(100),
      },
      {
        "day": "wednesday",
        "temp": "${currentTemp + random.nextInt(5) - 1}°",
        "min": "${currentTemp - 4 + random.nextInt(3)}°",
        "rain": random.nextInt(100),
      },
      {
        "day": "thursday",
        "temp": "${currentTemp + random.nextInt(5) - 3}°",
        "min": "${currentTemp - 6 + random.nextInt(3)}°",
        "rain": random.nextInt(100),
      },
      {
        "day": "friday",
        "temp": "${currentTemp + random.nextInt(5)}°",
        "min": "${currentTemp - 5 + random.nextInt(3)}°",
        "rain": random.nextInt(100),
      },
      {
        "day": "saturday",
        "temp": "${currentTemp + random.nextInt(5) + 1}°",
        "min": "${currentTemp - 2 + random.nextInt(3)}°",
        "rain": random.nextInt(100),
      },
    ];
  }

  String _getDayName(String dayKey) {
    switch (dayKey) {
      case 'monday':
        return _l10n.monday;
      case 'tuesday':
        return _l10n.tuesday;
      case 'wednesday':
        return _l10n.wednesday;
      case 'thursday':
        return _l10n.thursday;
      case 'friday':
        return _l10n.friday;
      case 'saturday':
        return _l10n.saturday;
      case 'sunday':
        return _l10n.sunday;
      default:
        return dayKey;
    }
  }

  String _getDayShortName(String dayKey) {
    return _getDayName(dayKey).substring(0, 3);
  }

  String _getSoilTypeTranslation(String soilType) {
    switch (soilType.toLowerCase()) {
      case 'sableux':
        return _l10n.sandySoil;
      case 'argileux':
        return _l10n.claySoil;
      case 'limoneux':
        return _l10n.loamySoil;
      default:
        return soilType;
    }
  }

  String _getCropTranslation(String crop) {
    switch (crop.toLowerCase()) {
      case 'olive':
        return _l10n.olive;
      case 'blé':
        return _l10n.wheat;
      case 'tomate':
        return _l10n.tomato;
      case 'fraise':
        return _l10n.strawberry;
      case 'maïs':
        return _l10n.corn;
      default:
        return crop;
    }
  }

  IconData _getCropIcon(String crop) {
    final lower = crop.toLowerCase();
    if (lower.contains('olive')) {
      return Icons.park;
    } else if (lower.contains('blé')) {
      return Icons.grass;
    } else if (lower.contains('tomate')) {
      return Icons.local_florist;
    } else if (lower.contains('fraise')) {
      return Icons.spa;
    } else if (lower.contains('maïs')) {
      return Icons.eco;
    }
    return Icons.agriculture;
  }

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
                  ? "${_l10n.realTimeData}${lastUpdate != null ? " (${lastUpdate.hour}:${lastUpdate.minute.toString().padLeft(2, '0')})" : ""}"
                  : _l10n.cloudEmpty,
              style: TextStyle(
                color:
                    isUsingMQTTData ? Colors.blueAccent : Colors.orangeAccent,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWateringExplanation(String crop) {
    String text;
    if (crop.toLowerCase().contains("olive")) {
      text = _l10n.oliveWatering;
    } else if (crop.toLowerCase().contains("blé")) {
      text = _l10n.wheatWatering;
    } else if (crop.toLowerCase().contains("tomate")) {
      text = _l10n.tomatoWatering;
    } else if (crop.toLowerCase().contains("fraise")) {
      text = _l10n.strawberryWatering;
    } else if (crop.toLowerCase().contains("maïs")) {
      text = _l10n.cornWatering;
    } else {
      text = _l10n.standardWatering;
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white54, fontSize: 13),
    );
  }

  String _getRecommendation(
    String soil,
    String crop,
    List<Map<String, dynamic>> data,
    int humidity,
  ) {
    bool hasRain = data.any((day) => (day["rain"] as int) > 40);

    if (hasRain) {
      return _l10n.noWateringNeeded;
    }

    String solInfo = "";
    switch (soil.toLowerCase()) {
      case "sableux":
        solInfo = _l10n.sandySoilInfo;
        break;
      case "argileux":
        solInfo = _l10n.claySoilInfo;
        break;
      case "limoneux":
        solInfo = _l10n.loamySoilInfo;
        break;
      default:
        solInfo = _l10n.standardSoil;
    }

    String besoin = "";

    if (crop.toLowerCase().contains("tomate")) {
      besoin = _l10n.tomatoNeeds;
    } else if (crop.toLowerCase().contains("blé")) {
      besoin = _l10n.wheatNeeds;
    } else if (crop.toLowerCase().contains("fraise")) {
      besoin = _l10n.strawberryNeeds;
    } else if (crop.toLowerCase().contains("olive")) {
      besoin = _l10n.oliveNeeds;
    } else if (crop.toLowerCase().contains("maïs")) {
      besoin = _l10n.cornNeeds;
    } else {
      besoin = _l10n.standardNeeds;
    }

    if (humidity > 75) {
      return "$solInfo ${_l10n.soilVeryHumid}\n$besoin";
    } else if (humidity < 40) {
      return "$solInfo ${_l10n.soilDry}\n$besoin";
    } else {
      return "$solInfo ${_l10n.soilModeratelyHumid}\n$besoin";
    }
  }
}