import 'package:flutter/material.dart';
import 'dart:math';
import '../../services/mqtt_service.dart';
import '../../services/weather_service.dart';
import '../../models/sensor_data.dart';
import '../../models/weather_data.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/animated_humidity_circle.dart';
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
  bool _showWeeklyWeather = false;
  late AppLocalizations _l10n;

  // Thème local pour cette page (toggle sombre / clair)
  ThemeData _currentTheme = AppTheme.lightTheme;
  bool _isDarkTheme = false;
  bool _isIrrigationPlanActive = false;
  DateTime? _irrigationStartDate;
  int _recommendedInterval = 2; // Intervalle recommandé par l'API

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
    final theme = _currentTheme;
    final colorScheme = theme.colorScheme;

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: _isDarkTheme ? Colors.black : const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor:
              _isDarkTheme ? const Color(0xFF1A1A1A) : const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text(
            "${_l10n.irrigationPlan} - ${widget.location}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isDarkTheme ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isDarkTheme = !_isDarkTheme;
                  _currentTheme = _isDarkTheme
                      ? AppTheme.irrigationTheme
                      : AppTheme.lightTheme;
                });
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // 🌤️ BANDE MÉTEO
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isDarkTheme
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDarkTheme
                      ? Colors.grey.withOpacity(0.3)
                      : const Color(0xFF4CAF50).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isDarkTheme
                        ? Colors.black.withOpacity(0.5)
                        : Colors.black.withOpacity(0.1),
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
                        color: _isDarkTheme
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFE8F5E8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isDarkTheme
                              ? Colors.grey.shade600
                              : const Color(0xFF4CAF50),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: _isDarkTheme
                                    ? Colors.grey.shade300
                                    : const Color(0xFF2E7D32),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '✅ ${_currentWeather!.cityName}: '
                                  '${_currentWeather!.temperature.round()}°C - '
                                  '${_currentWeather!.description}',
                                  style: TextStyle(
                                    color: _isDarkTheme
                                        ? Colors.white
                                        : const Color(0xFF2E7D32),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (weatherData.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Prévision sur 1 semaine',
                                  style: TextStyle(
                                    color: _isDarkTheme
                                        ? Colors.white70
                                        : const Color(0xFF2E7D32),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _showWeeklyWeather = !_showWeeklyWeather;
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  child: Text(
                                    'Voir la semaine',
                                    style: TextStyle(
                                      color: _isDarkTheme
                                          ? Colors.white
                                          : const Color(0xFF4CAF50),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (_showWeeklyWeather) ...[
                              Column(
                                children: weatherData.map((day) {
                                  final int rainValue = day['rain'] as int;
                                  final String temp = day['temp'] as String;
                                  final String minTemp = day['min'] as String;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _getDayName(day['day'] as String),
                                          style: TextStyle(
                                            color: _isDarkTheme
                                                ? Colors.white54
                                                : Colors.black,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.thermostat,
                                              color: _isDarkTheme
                                                  ? Colors.white
                                                  : const Color(0xFF4CAF50),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$temp / $minTemp',
                                              style: TextStyle(
                                                color: _isDarkTheme
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.water_drop,
                                              color: _isDarkTheme
                                                  ? Colors.white
                                                  : const Color(0xFF4CAF50),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$rainValue%',
                                              style: TextStyle(
                                                color: _isDarkTheme
                                                    ? Colors.white
                                                    : const Color(0xFF4CAF50),
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
                              Builder(
                                builder: (context) {
                                  final totalRain = weatherData
                                      .map((d) => d['rain'] as int)
                                      .fold<int>(0, (sum, v) => sum + v);
                                  final avgRain =
                                      (totalRain / weatherData.length).round();
                                  return Text(
                                    'Humidité moyenne de la semaine : $avgRain%',
                                    style: TextStyle(
                                      color: _isDarkTheme
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                            ],
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
    final colorScheme = Theme.of(context).colorScheme;

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
        color: _isDarkTheme ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _isDarkTheme
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: _isDarkTheme
                      ? Colors.grey.shade800
                      : const Color(0xFF4CAF50).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getCropIcon(crop),
                  color: const Color(0xFF4CAF50),
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
                      style: TextStyle(
                        color: _isDarkTheme
                            ? Colors.white
                            : const Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${_l10n.soil} : ${_getSoilTypeTranslation(widget.soilType)}",
                      style: TextStyle(
                        color: _isDarkTheme
                            ? Colors.white70
                            : const Color(0xFF2E7D32).withOpacity(0.7),
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
            color: _isDarkTheme
                ? Colors.grey.shade700
                : Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 14),
          _buildWateringCalendar(weatherData, crop),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.secondary.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: _buildWateringExplanation(crop),
          ),
          const SizedBox(height: 20),
          _buildSoilHumidityWidget(soilHumidity),
          const SizedBox(height: 10),
          _buildDataSourceWidget(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.secondary.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              "${_l10n.aiAdviceFor} ${_getCropTranslation(crop)} :\n$recommendation",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
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
    String status;

    if (humidity < 30) {
      status = _l10n.drySoil;
    } else if (humidity < 60) {
      status = _l10n.mediumHumidity;
    } else {
      status = _l10n.humidSoil;
    }

    const Color primary = Colors.orange; // même couleur que ton exemple

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // fond clair
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.water_drop,
            color: Colors.blue,
          ),
          const SizedBox(height: 4),
          Text(
            'Current ${_currentWeather?.temperature.round() ?? 0}°C',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedHumidityCircle(
            humidity: humidity,
            color: primary,
          ),
          const SizedBox(height: 12),
          Text(
            status,
            style: const TextStyle(
              color: primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWateringCalendar(
    List<Map<String, dynamic>> weatherData,
    String crop,
  ) {
    // Calculer l'intervalle recommandé selon la culture
    int _recommendedInterval;

    if (crop.toLowerCase().contains("olive")) {
      _recommendedInterval = 7;
    } else if (crop.toLowerCase().contains("blé")) {
      _recommendedInterval = 1;
    } else if (crop.toLowerCase().contains("tomate")) {
      _recommendedInterval = 2;
    } else if (crop.toLowerCase().contains("fraise")) {
      _recommendedInterval = 1;
    } else if (crop.toLowerCase().contains("maïs")) {
      _recommendedInterval = 3;
    } else {
      _recommendedInterval = 2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Plan d'arrosage",
          style: TextStyle(
            color: _isDarkTheme ? Colors.white : const Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),

        // RECOMMANDATIONS API
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                _isDarkTheme ? const Color(0xFF2A2A2A) : const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isDarkTheme
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.blue.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: _isDarkTheme
                        ? Colors.blue.shade300
                        : Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Recommandation IA",
                    style: TextStyle(
                      color: _isDarkTheme
                          ? Colors.blue.shade300
                          : Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Pour ${_getCropTranslation(crop)}, il est recommandé d'arroser tous les $_recommendedInterval jour${_recommendedInterval > 1 ? 's' : ''}.",
                style: TextStyle(
                  color: _isDarkTheme ? Colors.white70 : Colors.black87,
                  fontSize: 13,
                ),
              ),
              if (_currentWeather != null) ...[
                const SizedBox(height: 6),
                Text(
                  "Conditions actuelles: ${_currentWeather!.temperature.round()}°C, ${_currentWeather!.description}",
                  style: TextStyle(
                    color: _isDarkTheme ? Colors.white54 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // CONTRÔLES UTILISATEUR
        if (!_isIrrigationPlanActive)
          // Plan pas encore démarré
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDarkTheme ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDarkTheme
                    ? Colors.green.withOpacity(0.3)
                    : const Color(0xFF4CAF50).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  color: _isDarkTheme
                      ? Colors.green.shade300
                      : const Color(0xFF4CAF50),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  "Prêt à commencer l'arrosage ?",
                  style: TextStyle(
                    color: _isDarkTheme ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Vous décidez quand démarrer le plan d'arrosage recommandé.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isDarkTheme ? Colors.white70 : Colors.black54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),

                // BOUTON START AMÉLIORÉ
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isIrrigationPlanActive = true;
                      _irrigationStartDate = DateTime.now();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "✅ Plan d'arrosage démarré ! Arrosage tous les $_recommendedInterval jour${_recommendedInterval > 1 ? 's' : ''}.",
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF43A047),
                          Color(0xFF66BB6A),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.9, end: 1.05),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.15),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Démarrer le plan d'arrosage",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              "Arrosage tous les $_recommendedInterval jour${_recommendedInterval > 1 ? 's' : ''}",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          // Plan actif - Afficher le calendrier
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDarkTheme ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDarkTheme
                    ? Colors.green.withOpacity(0.3)
                    : const Color(0xFF4CAF50).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: _isDarkTheme
                              ? Colors.green.shade300
                              : const Color(0xFF4CAF50),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Plan actif",
                          style: TextStyle(
                            color: _isDarkTheme
                                ? Colors.green.shade300
                                : const Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isIrrigationPlanActive = false;
                          _irrigationStartDate = null;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("⏹️ Plan d'arrosage arrêté"),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.stop,
                        color: _isDarkTheme
                            ? Colors.orange.shade300
                            : Colors.orange.shade700,
                        size: 16,
                      ),
                      label: Text(
                        "Arrêter",
                        style: TextStyle(
                          color: _isDarkTheme
                              ? Colors.orange.shade300
                              : Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_irrigationStartDate != null) ...[
                  Text(
                    "Démarré le: ${_irrigationStartDate!.day}/${_irrigationStartDate!.month}/${_irrigationStartDate!.year}",
                    style: TextStyle(
                      color: _isDarkTheme ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Calendrier des 7 prochains jours
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weatherData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final day = entry.value;
                    final int rainValue = day["rain"] as int;
                    bool isRain = rainValue > 40;

                    bool shouldWater = false;
                    if (!isRain) {
                      if (_recommendedInterval == 1) {
                        shouldWater = true;
                      } else if (index % _recommendedInterval == 0) {
                        shouldWater = true;
                      }
                    }

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 350 + index * 80),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 12 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Text(
                            _getDayShortName((day["day"] as String)),
                            style: TextStyle(
                              color: _isDarkTheme
                                  ? Colors.white54
                                  : const Color(0xFF757575),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            shouldWater ? Icons.water_drop : Icons.cloud,
                            color: shouldWater
                                ? (_isDarkTheme
                                    ? Colors.white
                                    : const Color(0xFF4CAF50))
                                : (_isDarkTheme
                                    ? Colors.white70
                                    : const Color(0xFF2196F3)),
                            size: 22,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            shouldWater ? _l10n.waterToday : _l10n.rest,
                            style: TextStyle(
                              color: shouldWater
                                  ? (_isDarkTheme
                                      ? Colors.white
                                      : const Color(0xFF4CAF50))
                                  : (_isDarkTheme
                                      ? Colors.white54
                                      : const Color(0xFF757575)),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Génère des données météo hebdomadaires à partir de la météo actuelle
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

    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isUsingMQTTData
            ? cs.primary.withOpacity(0.15)
            : cs.secondary.withOpacity(0.15),
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
      style: TextStyle(
        color: _isDarkTheme ? Colors.white : const Color(0xFF2E7D32),
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
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