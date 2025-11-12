import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

class WeatherService {
  static const String _apiKey =
      '5b5277977c83d8b2e41353bacdd4737f'; // À remplacer
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Villes agricoles par défaut - Tunisie
  static const Map<String, Map<String, double>> _agriculturalLocations = {
    'Tunis': {'lat': 36.8065, 'lon': 10.1815},
    'Sfax': {'lat': 34.7406, 'lon': 10.7603},
    'Sousse': {'lat': 35.8256, 'lon': 10.6369},
    'Kairouan': {'lat': 35.6781, 'lon': 10.0963},
    'Bizerte': {'lat': 37.2744, 'lon': 9.8739},
    'Gabès': {'lat': 33.8815, 'lon': 10.0982},
    'Ariana': {'lat': 36.8625, 'lon': 10.1956},
    'Monastir': {'lat': 35.7643, 'lon': 10.8113},
  };

  Future<WeatherData> getWeatherByCity(String cityName) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric&lang=fr',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Erreur API météo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur connexion météo: $e');
    }
  }

  Future<WeatherData> getWeatherByCoordinates(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=fr',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Erreur API météo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur connexion météo: $e');
    }
  }

  Future<List<WeatherData>> getAgriculturalWeather() async {
    final List<WeatherData> weatherList = [];

    for (final location in _agriculturalLocations.entries) {
      try {
        final weather = await getWeatherByCoordinates(
          location.value['lat']!,
          location.value['lon']!,
        );
        weatherList.add(weather);
      } catch (e) {
        print('Erreur météo pour ${location.key}: $e');
      }
    }

    return weatherList;
  }

  Future<WeatherData> getCurrentLocationWeather() async {
    // Par défaut Tunis, vous pourrez intégrer la géolocalisation plus tard
    return await getWeatherByCity('Tunis');
  }
}
