// presentation/providers/sensor_provider.dart
import 'package:flutter/foundation.dart';
import '../../models/sensor_data.dart';
import '../../services/sensor_api_service.dart';

class SensorProvider with ChangeNotifier {
  final SensorApiService _sensorService = SensorApiService();
  
  List<SensorData> _sensors = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SensorData> get sensors => _sensors;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 📊 CHARGER TOUS LES CAPTEURS
  Future<void> loadAllSensors({int limit = 100}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _sensorService.getAllSensors(limit: limit);

    _isLoading = false;

    if (result['success']) {
      _sensors = result['sensors'];
    } else {
      _errorMessage = result['message'];
    }

    notifyListeners();
  }

  // 📍 CHARGER UN CAPTEUR SPÉCIFIQUE
  Future<void> loadSensorByDevice(String deviceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _sensorService.getSensorByDevice(deviceId);

    _isLoading = false;

    if (result['success']) {
      _sensors = result['sensors'];
    } else {
      _errorMessage = result['message'];
    }

    notifyListeners();
  }

  // 🗑️ SUPPRIMER DES DONNÉES
  Future<bool> deleteSensor(String id) async {
    final result = await _sensorService.deleteSensor(id);

    if (result['success']) {
      _sensors.removeWhere((sensor) => sensor.id == id);
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // 🔄 RAFRAÎCHIR
  Future<void> refresh() async {
    await loadAllSensors();
  }
}