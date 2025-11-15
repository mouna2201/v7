import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/weather_service.dart';
import '../../models/weather_data.dart';

class WeatherNotifier with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();

  WeatherData? _currentWeather;
  List<WeatherData> _agriculturalWeather = [];
  bool _isLoading = false;
  String _error = '';

  WeatherData? get currentWeather => _currentWeather;
  List<WeatherData> get agriculturalWeather => _agriculturalWeather;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> loadCurrentWeather({String? location}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      if (location != null && location.isNotEmpty) {
        _currentWeather = await _weatherService.getWeatherByCity(location);
      } else {
        _currentWeather = await _weatherService.getCurrentLocationWeather();
      }
    } catch (e) {
      _error = 'Erreur météo: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAgriculturalWeather() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _agriculturalWeather = await _weatherService.getAgriculturalWeather();
    } catch (e) {
      _error = 'Erreur météo agricole: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAllWeather() async {
    await loadCurrentWeather();
    await loadAgriculturalWeather();
  }

  Future<void> loadWeatherForCity(String cityName) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentWeather = await _weatherService.getWeatherByCity(cityName);
      _error = '';
    } catch (e) {
      _error = 'Erreur pour $cityName: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Provider pour le WeatherNotifier
final weatherProvider = Provider<WeatherNotifier>((ref) {
  return WeatherNotifier();
});
