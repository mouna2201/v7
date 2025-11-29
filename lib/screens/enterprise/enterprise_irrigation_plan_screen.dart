import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/mqtt_service.dart';
import '../../services/weather_service.dart';
import '../../services/notification_service.dart';
import '../../services/mistral_service.dart';
import '../farmer/farmer_form_screen.dart';

import '../../models/sensor_data.dart';
import '../../models/weather_data.dart';
import '../../models/crop_history.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/animated_humidity_circle.dart';
import '../../widgets/custom_button.dart';
import '../welcome/welcome_screen.dart';

class EnterpriseIrrigationPlanScreen extends StatefulWidget {
  final String location;
  final String soilType;
  final List<String> cropTypes;
  final bool isSupervisor;
  final double? areaM2;
  final String? farmerName;
  final String? farmerAddress;

  const EnterpriseIrrigationPlanScreen({
    super.key,
    required this.location,
    required this.soilType,
    required this.cropTypes,
    this.isSupervisor = true, // Par défaut true pour entreprise
    this.areaM2,
    this.farmerName,
    this.farmerAddress,
  });

  @override
  State<EnterpriseIrrigationPlanScreen> createState() => _EnterpriseIrrigationPlanScreenState();
}

class _EnterpriseIrrigationPlanScreenState extends State<EnterpriseIrrigationPlanScreen>
    with TickerProviderStateMixin {
  late AppLocalizations _l10n;
  final MQTTService _mqttService = MQTTService();
  final WeatherService _weatherService = WeatherService();
  final MistralService _mistralService = MistralService();
  final NotificationService _notificationService = NotificationService();

  // États
  List<SensorData> _sensorData = [];
  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = true;
  bool _isLoadingMistral = false;
  String? _mistralError;
  List<IrrigationPlanHistoryRecord> _irrigationHistory = [];
  bool _isLoadingHistory = true;

  // Thème
  bool _isDarkTheme = false;
  late ThemeData _currentTheme;

  // Contrôleurs pour les rappels
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime? _selectedStartDate;
  bool _isIrrigationPlanActive = false;
  int? _recommendedInterval;

  // Animation controller
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _l10n = AppLocalizations.of(context)!;
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _loadWeatherForLocation();
    _loadCropHistory();
    _initializeMQTT();
    _setupTheme();
  }

  void _setupTheme() {
    setState(() {
      _currentTheme = _isDarkTheme ? AppTheme.darkTheme : AppTheme.lightTheme;
    });
  }

  void _initializeMQTT() {
    _mqttService.connect();
    _mqttService.subscribe('farm/soil1');
    _mqttService.messageStream.listen((message) {
      try {
        final data = jsonDecode(message);
        final sensorReading = SensorData.fromJson(data);
        setState(() {
          _sensorData.add(sensorReading);
          if (_sensorData.length > 100) {
            _sensorData.removeAt(0);
          }
        });
      } catch (e) {
        print('Erreur parsing MQTT: $e');
      }
    });
  }

  Future<void> _loadWeatherForLocation() async {
    try {
      setState(() => _isLoadingWeather = true);
      final weather = await _weatherService.getWeatherForLocation(widget.location);
      setState(() {
        _weatherData = weather;
        _isLoadingWeather = false;
      });
    } catch (e) {
      print('Erreur chargement météo: $e');
      setState(() {
        _isLoadingWeather = false;
      });
    }
  }

  Future<void> _loadCropHistory() async {
    try {
      final history = await _authService.getCropHistory();
      setState(() {
        _irrigationHistory = history;
        _isLoadingHistory = false;
      });
    } catch (e) {
      print('Erreur chargement historique: $e');
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mqttService.disconnect();
    super.dispose();
  }

  Color _getCropTypeColor() {
    final Map<String, Color> cropColors = {
      'Fraise': const Color(0xFFE91E63),
      'Tomate': const Color(0xFFFF5722),
      'Maïs': const Color(0xFFFFC107),
      'Olive': const Color(0xFF8BC34A),
      'Blé': const Color(0xFFFFD54F),
      'Orge': const Color(0xFFD4A373),
      'Vigne': const Color(0xFF9C27B0),
      'Agrume': const Color(0xFF4CAF50),
      'Légume': const Color(0xFF00BCD4),
      'Fruit': const Color(0xFFFF6B6B),
    };
    
    final firstCrop = widget.cropTypes.isNotEmpty ? widget.cropTypes.first.toLowerCase() : '';
    for (var entry in cropColors.entries) {
      if (entry.key.toLowerCase() == firstCrop) return entry.value;
    }
    
    return _isDarkTheme ? const Color(0xFF2E7D32).withOpacity(0.8) : const Color(0xFF4CAF50).withOpacity(0.9);
  }

  Color get _primaryColor {
    if (widget.cropTypes.isNotEmpty) {
      final colors = _getCropBackgroundColor(widget.cropTypes.first);
      final primary = colors['primary'];
      if (primary != null) return primary;
    }
    return widget.isSupervisor
        ? const Color(0xFF1976D2)
        : const Color(0xFF4CAF50);
  }

  Map<String, Color> _getCropBackgroundColor(String cropType) {
    final Map<String, Map<String, Color>> cropColors = {
      'Fraise': {
        'primary': const Color(0xFFE91E63),
        'secondary': const Color(0xFFF48FB1),
        'accent': const Color(0xFFC2185B),
      },
      'Tomate': {
        'primary': const Color(0xFFFF5722),
        'secondary': const Color(0xFFFFAB91),
        'accent': const Color(0xFFE64A19),
      },
      'Maïs': {
        'primary': const Color(0xFFFFC107),
        'secondary': const Color(0xFFFFE082),
        'accent': const Color(0xFFFFA000),
      },
      'Olive': {
        'primary': const Color(0xFF8BC34A),
        'secondary': const Color(0xFFC5E1A5),
        'accent': const Color(0xFF689F38),
      },
    };
    
    final lowerCrop = cropType.toLowerCase();
    for (var entry in cropColors.entries) {
      if (entry.key.toLowerCase() == lowerCrop) return entry.value;
    }
    
    return {
      'primary': const Color(0xFF4CAF50),
      'secondary': const Color(0xFF81C784),
      'accent': const Color(0xFF388E3C),
    };
  }

  List<Color> _getCropGradient(String cropType) {
    final colors = _getCropBackgroundColor(cropType);
    return [
      colors['primary']!,
      colors['secondary']!,
    ];
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _getCropTranslation(String crop) {
    final translations = {
      'Fraise': _l10n.strawberry,
      'Tomate': _l10n.tomato,
      'Maïs': _l10n.corn,
      'Olive': _l10n.olive,
      'Blé': _l10n.wheat,
      'Orge': _l10n.barley,
      'Vigne': _l10n.vineyard,
      'Agrume': _l10n.citrus,
      'Légume': _l10n.vegetable,
      'Fruit': _l10n.fruit,
    };
    return translations[crop] ?? crop;
  }

  String _getSoilTypeTranslation(String soilType) {
    final translations = {
      'argileux': _l10n.claySoil,
      'sableux': _l10n.sandySoil,
      'limoneux': _l10n.loamySoil,
      'calcaire': _l10n.limestoneSoil,
      'humus': _l10n.humusSoil,
      'rocheux': _l10n.rockySoil,
    };
    return translations[soilType] ?? soilType;
  }

  Map<String, dynamic> _generateWeatherData() {
    final random = Random();
    return {
      'temp': (15 + random.nextDouble() * 20).toStringAsFixed(1),
      'humidity': (40 + random.nextDouble() * 40).toInt(),
      'rain': (0 + random.nextDouble() * 10).toInt(),
    };
  }

  Future<void> _startIrrigationPlan() async {
    if (_selectedStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une date de début'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoadingMistral = true);
    _mistralError = null;

    try {
      final weatherData = _generateWeatherData();
      final area = widget.areaM2 ?? 1000;
      final areaPerCrop = area / widget.cropTypes.length;

      for (final cropType in widget.cropTypes) {
        double waterAmount = _extractWaterAmountFromPlan(
          {
            'location': widget.location,
            'soilType': widget.soilType,
            'cropType': cropType,
            'area': areaPerCrop,
            'weather': weatherData,
          },
          areaPerCrop,
        );

        final success = await _authService.saveCropHistory(
          location: widget.location,
          cropType: cropType,
          area: areaPerCrop,
          soilType: widget.soilType,
          waterAmount: waterAmount,
        );
      }

      NotificationService().scheduleIrrigationReminder(
        crop: _getCropTranslation(widget.cropTypes.first),
        intervalDays: _recommendedInterval ?? 2,
        startTime: _reminderTime,
        startDate: _selectedStartDate!,
      );

      setState(() {
        _isIrrigationPlanActive = true;
        _isLoadingMistral = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ Plan d'arrosage IA démarré ! Arrosage tous les $_recommendedInterval jour${_recommendedInterval! > 1 ? 's' : ''}.",
          ),
          backgroundColor: _getCropTypeColor(),
        ),
      );
    } catch (e) {
      setState(() {
        _mistralError = e.toString();
        _isLoadingMistral = false;
      });
    }
  }

  double _extractWaterAmountFromPlan(Map<String, dynamic> plan, double area) {
    final baseWaterPerSqm = 5.0;
    final cropMultiplier = plan['cropType'].toString().toLowerCase() == 'tomate' ? 1.2 : 1.0;
    return (baseWaterPerSqm * area * cropMultiplier);
  }

  Future<List<IrrigationPlanHistoryRecord>> _fetchIrrigationPlanHistoryForCrop(String crop) async {
    try {
      final allHistory = await _authService.getCropHistory();
      final cropHistory = allHistory.where((record) => record.cropType == crop).toList();
      return cropHistory;
    } catch (e) {
      print('Erreur récupération historique pour $crop: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherData = _generateWeatherData();
    final theme = _currentTheme;

    return Theme(
      data: theme,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    FarmerFormScreen(farmerName: widget.farmerName ?? 'Agriculteur'),
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
          title: Column(
            children: [
              Text(
                "${_l10n.irrigationPlan} - ${widget.location}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              if (widget.farmerName != null)
                Text(
                  "${widget.farmerName}${widget.farmerAddress != null ? ' - ${widget.farmerAddress}' : ''}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.logout),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isDarkTheme = !_isDarkTheme;
                  _currentTheme = _isDarkTheme ? AppTheme.darkTheme : AppTheme.lightTheme;
                });
              },
              icon: Icon(_isDarkTheme ? Icons.light_mode : Icons.dark_mode),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Informations du fermier
              if (widget.farmerName != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getCropTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getCropTypeColor().withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getCropTypeColor().withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: _getCropTypeColor(),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.farmerName!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getCropTypeColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.farmerAddress != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: _getCropTypeColor(),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.farmerAddress!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _getCropTypeColor().withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

              // Section parcelle
              if (widget.areaM2 != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _getCropTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getCropTypeColor().withOpacity(0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getCropTypeColor().withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.landscape,
                            size: 18,
                            color: _getCropTypeColor(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Parcelle : ${widget.location}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _getCropTypeColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.areaM2!.toStringAsFixed(0)} m² • Sol : ${_getSoilTypeTranslation(widget.soilType)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getCropTypeColor().withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),

              // Section météo
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getCropTypeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getCropTypeColor().withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cloud, color: _getCropTypeColor(), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "MÉTÉO - ${widget.location.toUpperCase()}",
                            style: TextStyle(
                              color: _getCropTypeColor(),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isLoadingWeather)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(_getCropTypeColor()),
                          ),
                        ),
                      )
                    else if (_weatherData != null)
                      _buildWeatherCardGreenStyle([_weatherData!])
                    else
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Données météo non disponibles',
                          style: TextStyle(color: _getCropTypeColor()),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Column(
                children: [
                  _buildSoilHumidityWidget(50),
                  const SizedBox(height: 20),
                  _buildWateringCalendar(weatherData, widget.cropTypes.first),
                  const SizedBox(height: 20),
                  FutureBuilder<List<IrrigationPlanHistoryRecord>>(
                    future: _fetchIrrigationPlanHistoryForCrop(widget.cropTypes.first),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Erreur de chargement',
                            style: TextStyle(color: Colors.red[300]),
                          ),
                        );
                      }

                      final history = snapshot.data ?? [];

                      if (history.isEmpty) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _isDarkTheme ? const Color(0xFF1F2933) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.history,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Aucun historique disponible',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'L\'historique des plans d\'irrigation apparaîtra ici',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _isDarkTheme ? const Color(0xFF1F2933) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.history,
                                      color: _primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Historique des plans d\'irrigation',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...history.map((record) => _buildHistoryItem(record)).toList(),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoilHumidityWidget(int humidity) {
    Color primary;
    if (humidity < 30) {
      primary = Colors.red;
    } else if (humidity < 60) {
      primary = Colors.orange;
    } else {
      primary = _getCropTypeColor();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          Text(
            'Humidité du sol',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedHumidityCircle(
            humidity: humidity,
            animation: _animationController,
            primaryColor: primary,
            size: 120,
          ),
          const SizedBox(height: 16),
          Text(
            '$humidity%',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            humidity < 30 ? 'Sol sec - Arrosage recommandé' :
            humidity < 60 ? 'Humidité modérée' : 'Humidité optimale',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCardGreenStyle(
    List<Map<String, dynamic>> weatherData,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _getCropTypeColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getCropTypeColor().withOpacity(0.7),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: _getCropTypeColor(),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.check,
                    color: _getCropTypeColor(),
                    size: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Température: ${weatherData[0]['temp']}°C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: _getCropTypeColor(),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.check,
                    color: _getCropTypeColor(),
                    size: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Humidité: ${weatherData[0]['humidity']}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: _getCropTypeColor(),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    weatherData[0]['rain'] > 0 ? Icons.check : Icons.close,
                    color: weatherData[0]['rain'] > 0 ? _getCropTypeColor() : Colors.red,
                    size: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pluie: ${weatherData[0]['rain']} mm',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWateringCalendar(
    List<Map<String, dynamic>> weatherData,
    String crop,
  ) {
    final cropColors = _getCropBackgroundColor(crop);
    final cropGradient = _getCropGradient(crop);

    final lowerCrop = crop.toLowerCase();
    int soilHumidity = 50;

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

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: cropGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.water_drop,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calendrier d\'arrosage',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      _getCropTranslation(crop),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cropColors['primary']!.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: cropColors['primary']!.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: cropColors['primary'],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fréquence recommandée: Tous les $interval jours',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cropColors['primary'],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.opacity,
                      color: cropColors['primary'],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Basé sur: Humidité $soilHumidity%, Pluie $avgRain mm',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: _reminderTime,
                    );
                    if (picked != null) {
                      setState(() {
                        _reminderTime = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.grey[600],
                          size: 16,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Heure',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatTimeOfDay(_reminderTime),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedStartDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedStartDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.grey[600],
                          size: 16,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Début',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _selectedStartDate != null
                              ? '${_selectedStartDate!.day}/${_selectedStartDate!.month}'
                              : 'Aujourd\'hui',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: _isIrrigationPlanActive
                ? 'Plan d\'arrosage actif'
                : 'Démarrer le plan d\'arrosage IA',
            onPressed: _isIrrigationPlanActive ? null : _startIrrigationPlan,
            backgroundColor: cropColors['primary'],
            isLoading: _isLoadingMistral,
          ),
          if (_mistralError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red[200]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error,
                    color: Colors.red[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _mistralError!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryItem(IrrigationPlanHistoryRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.agriculture,
                color: _primaryColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  record.cropType,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ),
              Text(
                '${record.area.toStringAsFixed(0)} m²',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.water_drop,
                color: Colors.blue[600],
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                '${record.waterAmount.toStringAsFixed(1)} L',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                record.createdAt,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class IrrigationPlanHistoryRecord {
  final String cropType;
  final double area;
  final double waterAmount;
  final String createdAt;

  IrrigationPlanHistoryRecord({
    required this.cropType,
    required this.area,
    required this.waterAmount,
    required this.createdAt,
  });

  factory IrrigationPlanHistoryRecord.fromJson(Map<String, dynamic> json) {
    return IrrigationPlanHistoryRecord(
      cropType: json['cropType'] ?? '',
      area: (json['area'] ?? 0).toDouble(),
      waterAmount: (json['waterAmount'] ?? 0).toDouble(),
      createdAt: json['createdAt'] ?? '',
    );
  }
}
