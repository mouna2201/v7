import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/mqtt_service.dart';
import '../../services/weather_service.dart';
import '../../services/notification_service.dart';
import '../../services/mistral_service.dart';
import 'farmer_form_screen.dart';

import '../../models/sensor_data.dart';
import '../../models/weather_data.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/animated_humidity_circle.dart';
import '../welcome/welcome_screen.dart';
import 'watering_day_detail_screen.dart';

class IrrigationPlanScreen extends StatefulWidget {
  final String location;
  final String soilType;
  final List<String> cropTypes;
  final bool isSupervisor;

  const IrrigationPlanScreen({
    super.key,
    required this.location,
    required this.soilType,
    required this.cropTypes,
    this.isSupervisor = false,
  });

  @override
  State<IrrigationPlanScreen> createState() => _IrrigationPlanScreenState();
}

class _IrrigationPlanScreenState extends State<IrrigationPlanScreen> {
  final MQTTService _mqttService = MQTTService();
  final WeatherService _weatherService = WeatherService();
  final MistralService _mistralService = MistralService();
  SensorData? _latestSensorData;
  final List<SensorData> _sensorHistory = [];
  WeatherData? _currentWeather;
  bool _isLoadingWeather = true;
  String _weatherError = '';
  bool _showWeeklyWeather = false;
  late AppLocalizations _l10n;
  bool _isLoadingMistral = false;
  String? _mistralPlan;
  String? _mistralError;
  List<String>? _mistralWaterDaysKeys; // ex: ["monday","wednesday"]

  // Thème local pour cette page (toggle sombre / clair)
  ThemeData _currentTheme = AppTheme.lightTheme;
  bool _isDarkTheme = false;
  bool _isIrrigationPlanActive = false;
  DateTime? _irrigationStartDate;
  int _recommendedInterval = 2; // Intervalle recommandé par l'API
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime _selectedStartDate = DateTime.now();

  // Couleur principale du thème du plan d'arrosage (bleu pour tout le monde)
  Color get _primaryColor => const Color(0xFF1976D2);

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // TODO: adapter l'URL de base a ton serveur (localhost, IP, domaine)
  static const String _apiBaseUrl = 'http://localhost:3000';
  static const String _historyDeviceId = 'soil1';

  // TODO: remplace cette valeur par un vrai token JWT renvoyé par /api/users/login
  static const String _jwtToken = 'COLLE_ICI_UN_TOKEN_JWT_VALIDE';

  Future<List<HumidityRecord>> _fetchHumidityHistory() async {
    final uri = Uri.parse(
      '$_apiBaseUrl/api/capteurs/$_historyDeviceId?limit=50',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $_jwtToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur API historique: ${response.statusCode} ${response.body}',
      );
    }

    final Map<String, dynamic> body =
        json.decode(response.body) as Map<String, dynamic>;
    final List<dynamic> data = body['data'] as List<dynamic>;

    return data
        .map((e) => HumidityRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _initializeMQTT();
    _loadWeatherForLocation();
  }

  Future<void> _startIrrigationPlanWithMistral(String crop) async {
    setState(() {
      _isLoadingMistral = true;
      _mistralError = null;
    });

    try {
      final int soilHumidity = _latestSensorData?.soilMoisture?.toInt() ?? 0;
      final String weatherDescription =
          _currentWeather?.description ?? 'Inconnue';
      final num temperature = _currentWeather?.temperature ?? 0;

      final plan = await _mistralService.generateIrrigationPlan(
        location: widget.location,
        soilType: widget.soilType,
        crops: widget.cropTypes,
        soilHumidity: soilHumidity,
        weatherDescription: weatherDescription,
        temperature: temperature,
      );

      // Extraction éventuelle de la ligne technique "JOURS_ARROSAGE_CLES: ..."
      final regex = RegExp(
        r'JOURS_ARROSAGE_CLES:\s*([a-z,]+)',
        caseSensitive: false,
      );
      List<String>? waterKeys;
      final match = regex.firstMatch(plan);
      if (match != null) {
        final group = match.group(1);
        if (group != null) {
          waterKeys = group
              .split(',')
              .map((e) => e.trim().toLowerCase())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }

      setState(() {
        _mistralPlan = plan;
        _mistralWaterDaysKeys = waterKeys;
        _isIrrigationPlanActive = true;
        _irrigationStartDate = _selectedStartDate;
        _isLoadingMistral = false;
      });

      NotificationService().scheduleIrrigationReminder(
        crop: _getCropTranslation(crop),
        intervalDays: _recommendedInterval,
        startDate: _selectedStartDate,
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ Plan d'arrosage IA démarré ! Arrosage tous les $_recommendedInterval jour${_recommendedInterval > 1 ? 's' : ''}.",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _mistralError = e.toString();
        _isLoadingMistral = false;
      });
    }
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

  /// Icône météo animée (pluie / nuage / soleil) utilisée dans la bannière météo
  Widget _buildWeatherAnimatedIcon() {
    final description = _currentWeather?.description.toLowerCase() ?? '';

    bool isRain = description.contains('pluie') || description.contains('rain');
    bool isCloudy = description.contains('nuage') ||
        description.contains('cloud') ||
        description.contains('couvert') ||
        description.contains('overcast');

    // Si pas encore de météo chargée, icône neutre
    if (_currentWeather == null) {
      return const Icon(
        Icons.cloud,
        color: Colors.blue,
        size: 24,
      );
    }

    if (isRain) {
      // Animation simple de gouttes qui tombent sous un nuage
      return SizedBox(
        width: 32,
        height: 32,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
          onEnd: () {
            // relance l'animation en reconstruisant
            if (mounted) {
              setState(() {});
            }
          },
          builder: (context, value, child) {
            final dropOffset = 6 * value;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                  top: 2,
                  left: 4,
                  child: Icon(
                    Icons.cloud,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                Positioned(
                  top: 16 + dropOffset,
                  left: 8,
                  child: const Icon(
                    Icons.water_drop,
                    color: Colors.lightBlueAccent,
                    size: 14,
                  ),
                ),
                Positioned(
                  top: 16 + (dropOffset * 0.6),
                  left: 16,
                  child: const Icon(
                    Icons.water_drop,
                    color: Colors.lightBlueAccent,
                    size: 12,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    if (isCloudy) {
      // Nuage qui se déplace légèrement de gauche à droite
      return SizedBox(
        width: 32,
        height: 32,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: -2, end: 2),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOut,
          onEnd: () {
            if (mounted) {
              setState(() {});
            }
          },
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(value, 0),
              child: const Icon(
                Icons.cloud,
                color: Colors.blue,
                size: 24,
              ),
            );
          },
        ),
      );
    }

    // Cas par défaut : soleil qui pulse légèrement
    return SizedBox(
      width: 32,
      height: 32,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.9, end: 1.1),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
        onEnd: () {
          if (mounted) {
            setState(() {});
          }
        },
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: const Icon(
              Icons.wb_sunny,
              color: Colors.orangeAccent,
              size: 24,
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherCardWithAnimation(
    List<Map<String, dynamic>> weatherData,
  ) {
    final description = _currentWeather?.description.toLowerCase() ?? '';
    final bool isRain = description.contains('pluie') || description.contains('rain');

    Widget baseCard = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _isDarkTheme ? const Color(0xFF2A2A2A) : const Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              _isDarkTheme ? Colors.grey.shade600 : const Color(0xFF4CAF50),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // En-tête type iOS : ville / grosse température / description / Max-Min
          Text(
            _currentWeather!.cityName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _isDarkTheme ? Colors.white : Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_currentWeather!.temperature.round()}°',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _isDarkTheme ? Colors.white : Colors.black87,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _currentWeather!.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _isDarkTheme ? Colors.white70 : Colors.black54,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Max: --   Min: --',
            // À remplacer par de vraies valeurs min/max si ton modèle météo les fournit
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _isDarkTheme ? Colors.white54 : Colors.black45,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          if (weatherData.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prévision sur 1 semaine',
                  style: TextStyle(
                    color:
                        _isDarkTheme ? Colors.white70 : const Color(0xFF2E7D32),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getDayName(day['day'] as String),
                          style: TextStyle(
                            color:
                                _isDarkTheme ? Colors.white54 : Colors.black,
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
                      color:
                          _isDarkTheme ? Colors.white : Colors.black,
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
    );

    if (!isRain) {
      return baseCard;
    }

    // Ajoute une couche de "pluie" animée par-dessus toute la carte
    return Stack(
      children: [
        baseCard,
        Positioned.fill(
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeInOut,
              onEnd: () {
                if (mounted) {
                  setState(() {});
                }
              },
              builder: (context, value, child) {
                final double offsetY = 18 * value;
                return Opacity(
                  opacity: 0.7,
                  child: Transform.translate(
                    offset: Offset(0, offsetY),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (row) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(6, (col) {
                            return Icon(
                              Icons.water_drop,
                              size: 10,
                              color: Colors.white.withOpacity(0.35),
                            );
                          }),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FarmerFormScreen(farmerName: 'Agriculteur'),
              ),
            );
          },
          backgroundColor: _primaryColor,
          child: const Icon(Icons.edit_location_alt, color: Colors.white),
          tooltip: 'Modifier les détails de la parcelle',
        ),
        backgroundColor: _isDarkTheme ? Colors.black : const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor:
              _isDarkTheme ? const Color(0xFF1A1A1A) : _primaryColor,
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
              icon: const Icon(Icons.logout),
              tooltip: 'Exit',
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const WelcomeScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
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
            if (_isLoadingMistral || _mistralError != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoadingMistral)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_mistralError != null)
                      Text(
                        "Erreur Mistral : $_mistralError",
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                  ],
                ),
              ),
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
                      : _primaryColor.withOpacity(0.3),
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
                      _buildWeatherAnimatedIcon(),
                      const SizedBox(width: 8),
                      Text(
                        "MÉTÉO - ${widget.location.toUpperCase()}",
                        style: TextStyle(
                          color: widget.isSupervisor
                              ? const Color(0xFF1976D2)
                              : Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                    _buildWeatherCardWithAnimation(weatherData),
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
                            : _primaryColor,
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
                            : _primaryColor.withOpacity(0.7),
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
          // Humidité du sol en premier
          Center(
            child: _buildSoilHumidityWidget(soilHumidity),
          ),
          const SizedBox(height: 15),
          // Puis le plan d'arrosage
          _buildWateringCalendar(weatherData, crop),
          const SizedBox(height: 20),
          _buildDataSourceWidget(),
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

    // Couleur dynamique en fonction du niveau d'humidité
    Color primary;
    if (humidity < 30) {
      primary = Colors.red; // sol sec
    } else if (humidity < 60) {
      primary = Colors.orange; // humidité moyenne
    } else {
      primary = Colors.green; // sol bien humide
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.history),
            label: const Text('Historique'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    backgroundColor: const Color(0xFF0F172A),
                    appBar: AppBar(
                      backgroundColor: const Color(0xFF0F172A),
                      elevation: 0,
                      title: const Text(
                        "Historique d'humidité",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    body: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF0F172A),
                            Color(0xFF1B5E20),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Suivi de l'humidité du sol",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Retrouvez ici l'évolution des derniers pourcentages d'humidité.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Expanded(
                                child: FutureBuilder<List<HumidityRecord>>(
                                  future: _fetchHumidityHistory(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      );
                                    }

                                    if (snapshot.hasError) {
                                      return Center(
                                        child: Text(
                                          "Erreur de chargement de l'historique",
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    }

                                    final records = snapshot.data ?? [];

                                    // On n'applique plus de dédoublonnage ici :
                                    // l'historique affiche toutes les mesures renvoyées par l'API.

                                    if (records.isEmpty) {
                                      return Center(
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.06),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.12),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.25),
                                                blurRadius: 18,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: const [
                                              Icon(
                                                Icons.history,
                                                color: Colors.white,
                                                size: 42,
                                              ),
                                              SizedBox(height: 12),
                                              Text(
                                                "Aucun historique pour le moment",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                "Les prochaines valeurs reçues seront affichées ici.",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    return ListView.separated(
                                      itemCount: records.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (context, index) {
                                        final r = records[index];

                                        final d = r.timestamp;
                                        final dateStr =
                                            "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} "
                                            "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.06),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.12),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.water_drop,
                                                color: Colors.lightBlueAccent,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "${r.value.toStringAsFixed(0)} %",
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      dateStr,
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                r.deviceId,
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Calendrier d'arrosage + recommandation IA
  Widget _buildWateringCalendar(
    List<Map<String, dynamic>> weatherData,
    String crop,
  ) {
    final lowerCrop = crop.toLowerCase();
    int soilHumidity = _latestSensorData?.soilMoisture?.toInt() ?? 0;

    int baseInterval;
    if (lowerCrop.contains("olive")) {
      baseInterval = 7;
    } else if (lowerCrop.contains("blé")) {
      baseInterval = 2;
    } else if (lowerCrop.contains("tomate")) {
      baseInterval = 2;
    } else if (lowerCrop.contains("fraise")) {
      baseInterval = 1;
    } else if (lowerCrop.contains("maïs")) {
      baseInterval = 3;
    } else {
      baseInterval = 2;
    }

    int avgRain = 0;
    if (weatherData.isNotEmpty) {
      final totalRain = weatherData
          .map((d) => d['rain'] as int)
          .fold<int>(0, (sum, v) => sum + v);
      avgRain = (totalRain / weatherData.length).round();
    }

    int interval = baseInterval;
    if (soilHumidity < 30 && avgRain < 30) {
      interval = max(1, baseInterval - 1);
    } else if (soilHumidity > 70 || avgRain > 60) {
      interval = baseInterval + 1;
    }

    _recommendedInterval = interval;

    // Déterminer si aujourd'hui est un jour d'arrosage lorsque le plan est actif
    bool _isWateringReminderDay = false;
    if (_isIrrigationPlanActive && _irrigationStartDate != null) {
      final today = DateTime.now();
      final start = DateTime(
        _irrigationStartDate!.year,
        _irrigationStartDate!.month,
        _irrigationStartDate!.day,
      );
      final current = DateTime(today.year, today.month, today.day);
      final diffDays = current.difference(start).inDays;
      if (diffDays >= 0 && diffDays % _recommendedInterval == 0) {
        _isWateringReminderDay = true;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Plan d'arrosage",
          style: TextStyle(
            color: _isDarkTheme ? Colors.white : _primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),

        if (_isWateringReminderDay) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.notifications_active,
                  color: Colors.orange,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "💧 Rappel arrosage : aujourd'hui est un jour prévu par le plan.",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 10),

        // CALENDRIER DU PLAN (toujours affiché)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _isDarkTheme ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDarkTheme
                    ? _primaryColor.withOpacity(0.3)
                    : _primaryColor.withOpacity(0.3),
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
                          _isIrrigationPlanActive
                              ? Icons.check_circle
                              : Icons.calendar_today,
                          color: _isIrrigationPlanActive
                              ? (_isDarkTheme
                                  ? _primaryColor.withOpacity(0.8)
                                  : _primaryColor)
                              : (_isDarkTheme
                                  ? Colors.white70
                                  : _primaryColor),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isIrrigationPlanActive
                              ? "Plan actif"
                              : "Plan proposé",
                          style: TextStyle(
                            color: _isIrrigationPlanActive
                                ? (_isDarkTheme
                                    ? _primaryColor.withOpacity(0.8)
                                    : _primaryColor)
                                : (_isDarkTheme
                                    ? Colors.white70
                                    : _primaryColor),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (_isIrrigationPlanActive)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isIrrigationPlanActive = false;
                            _irrigationStartDate = null;
                            _mistralWaterDaysKeys = null;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("⏹️ Plan d'arrosage arrêté"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: _isDarkTheme
                              ? Colors.red.withOpacity(0.15)
                              : Colors.red.withOpacity(0.08),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: _isDarkTheme
                                  ? Colors.redAccent
                                  : Colors.red,
                              width: 1,
                            ),
                          ),
                        ),
                        icon: Icon(
                          Icons.stop_circle,
                          color:
                              _isDarkTheme ? Colors.redAccent : Colors.red,
                          size: 18,
                        ),
                        label: Text(
                          "Arrêter le plan",
                          style: TextStyle(
                            color:
                                _isDarkTheme ? Colors.redAccent : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: weatherData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final day = entry.value;
                    final String dayKey = day["day"] as String;
                    final int rainValue = day["rain"] as int;
                    bool isRain = rainValue > 40;

                    bool shouldWater = false;
                    if (!isRain) {
                      final dayKey = day["day"] as String;

                      // Si Mistral a fourni des jours précis, on les utilise
                      if (_mistralWaterDaysKeys != null &&
                          _mistralWaterDaysKeys!.isNotEmpty) {
                        shouldWater = _mistralWaterDaysKeys!
                            .contains(dayKey.toLowerCase());
                      } else {
                        // Sinon, on garde la logique automatique basée sur l'intervalle
                        if (_recommendedInterval == 1) {
                          shouldWater = true;
                        } else if (index % _recommendedInterval == 0) {
                          shouldWater = true;
                        }
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
                      child: GestureDetector(
                        onTap: shouldWater
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => WateringDayDetailScreen(
                                      dayKey: dayKey,
                                      crop: _getCropTranslation(crop),
                                      temperatureLabel:
                                          day["temp"] as String? ?? "-",
                                      rainPercent: rainValue,
                                      mistralPlan: _mistralPlan ?? "",
                                    ),
                                  ),
                                );
                              }
                            : null,
                        child: Column(
                          children: [
                            Text(
                              _getDayShortName((day["day"] as String)),
                              style: TextStyle(
                                color: _isDarkTheme
                                    ? Colors.white54
                                    : const Color(0xFF757575),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Icon(
                              shouldWater ? Icons.water_drop : Icons.cloud,
                              color: shouldWater
                                  ? (_isDarkTheme
                                      ? Colors.white
                                      : _primaryColor)
                                  : (_isDarkTheme
                                      ? Colors.white70
                                      : const Color(0xFF2196F3)),
                              size: 16,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              shouldWater ? _l10n.waterToday : _l10n.rest,
                              style: TextStyle(
                                color: shouldWater
                                    ? (_isDarkTheme
                                        ? Colors.white
                                        : _primaryColor)
                                    : (_isDarkTheme
                                        ? Colors.white54
                                        : const Color(0xFF757575)),
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // CONTRÔLES UTILISATEUR AFFICHÉS APRÈS LE PLAN
        if (!_isIrrigationPlanActive)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: _isDarkTheme
                  ? const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFE3F2FD), Color(0xFFE8F5FE)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: _isDarkTheme
                    ? _primaryColor.withOpacity(0.25)
                    : _primaryColor.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.95, end: 1.05),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isDarkTheme
                            ? [
                                Colors.green.shade400,
                                Colors.green.shade200,
                              ]
                            : const [
                                Color(0xFF4CAF50),
                                Color(0xFF8BC34A),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isDarkTheme
                                  ? Colors.lightBlueAccent
                                  : _primaryColor)
                              .withOpacity(0.4),
                          blurRadius: 14,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "Prêt à commencer l'arrosage ?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isDarkTheme ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Vous décidez quand démarrer le plan d'arrosage recommandé.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isDarkTheme ? Colors.white70 : Colors.black54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(_isDarkTheme ? 0.06 : 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_isDarkTheme
                              ? Colors.lightBlueAccent
                              : _primaryColor)
                          .withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event,
                        color: _isDarkTheme
                            ? Colors.lightBlueAccent
                            : _primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Début du plan : ${_selectedStartDate.day.toString().padLeft(2, '0')}/${_selectedStartDate.month.toString().padLeft(2, '0')}/${_selectedStartDate.year}",
                          style: TextStyle(
                            color: _isDarkTheme ? Colors.white : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final today = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedStartDate,
                            firstDate: DateTime(today.year - 1),
                            lastDate: DateTime(today.year + 2),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedStartDate = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                              );
                            });
                          }
                        },
                        child: const Text(
                          "Modifier",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(_isDarkTheme ? 0.06 : 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_isDarkTheme
                              ? Colors.greenAccent
                              : const Color(0xFF4CAF50))
                          .withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: _isDarkTheme
                            ? Colors.greenAccent
                            : const Color(0xFF4CAF50),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Heure du rappel : ${_formatTimeOfDay(_reminderTime)}",
                          style: TextStyle(
                            color: _isDarkTheme ? Colors.white : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _reminderTime,
                          );
                          if (picked != null) {
                            setState(() {
                              _reminderTime = picked;
                            });
                          }
                        },
                        child: const Text(
                          "Modifier",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    if (_isLoadingMistral) return;
                    _startIrrigationPlanWithMistral(crop);
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
                          Color(0xFF1976D2),
                          Color(0xFF42A5F5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1976D2).withOpacity(0.35),
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
      {
        "day": "sunday",
        "temp": "${currentTemp + random.nextInt(5)}°",
        "min": "${currentTemp - 3 + random.nextInt(3)}°",
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

class HumidityRecord {
  final double value;
  final DateTime timestamp;
  final String deviceId;

  HumidityRecord({
    required this.value,
    required this.timestamp,
    required this.deviceId,
  });

  factory HumidityRecord.fromJson(Map<String, dynamic> json) {
    // On essaye d'abord l'humidité du sol, puis l'humidité de l'air,
    // puis la température (cas des données Node-RED actuelles)
    final num? soil = json['humidite_sol'] as num?;
    final num? air = json['humidite'] as num?;
    final num? temp = json['temperature'] as num?;
    final num valueNum = soil ?? air ?? temp ?? 0;

    return HumidityRecord(
      value: valueNum.toDouble(),
      timestamp: DateTime.parse(json['timestamp_mesure'] as String),
      deviceId: json['device_id'] as String? ?? 'unknown',
    );
  }
}
