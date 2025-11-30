import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

class WeatherService {
  static const String _apiKey = '5b5277977c83d8b2e41353bacdd4737f';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Structure complète : Wilayas -> Villages avec coordonnées
  static const Map<String, Map<String, Map<String, double>>> _tunisiaLocations = {
    'Tunis': {
      'Tunis': {'lat': 36.8065, 'lon': 10.1815},
      'Le Bardo': {'lat': 36.8089, 'lon': 10.1406},
      'La Marsa': {'lat': 37.0761, 'lon': 10.3247},
      'Carthage': {'lat': 36.8531, 'lon': 10.3231},
    },
    'Ariana': {
      'Ariana': {'lat': 36.8625, 'lon': 10.1956},
      'Raoued': {'lat': 36.9333, 'lon': 10.1833},
      'Ettadhamen': {'lat': 36.8667, 'lon': 10.1333},
      'Mnihla': {'lat': 36.8833, 'lon': 10.0500},
    },
    'Ben Arous': {
      'Ben Arous': {'lat': 36.7467, 'lon': 10.2178},
      'Radès': {'lat': 36.7694, 'lon': 10.2753},
      'Hammam Lif': {'lat': 36.7289, 'lon': 10.3406},
      'Mégrine': {'lat': 36.7542, 'lon': 10.2333},
    },
    'Manouba': {
      'Manouba': {'lat': 36.8097, 'lon': 10.0964},
      'Oued Ellil': {'lat': 36.8333, 'lon': 10.0500},
      'Tebourba': {'lat': 36.8333, 'lon': 9.7500},
      'Douar Hicher': {'lat': 36.8167, 'lon': 10.1167},
    },
    'Nabeul': {
      'Nabeul': {'lat': 36.4561, 'lon': 10.7356},
      'Hammamet': {'lat': 36.4000, 'lon': 10.6167},
      'Korba': {'lat': 36.5789, 'lon': 10.8586},
      'Menzel Temime': {'lat': 36.7833, 'lon': 10.9833},
      'Kelibia': {'lat': 36.8472, 'lon': 11.0939},
      'Grombalia': {'lat': 36.6000, 'lon': 10.5000},
    },
    'Zaghouan': {
      'Zaghouan': {'lat': 36.4028, 'lon': 10.1433},
      'El Fahs': {'lat': 36.3833, 'lon': 9.9000},
      'Bir Mcherga': {'lat': 36.5167, 'lon': 10.0833},
    },
    'Bizerte': {
      'Bizerte': {'lat': 37.2744, 'lon': 9.8739},
      'Menzel Bourguiba': {'lat': 37.1542, 'lon': 9.7856},
      'Mateur': {'lat': 37.0403, 'lon': 9.6658},
      'Ras Jebel': {'lat': 37.2167, 'lon': 10.0333},
      'Sejnane': {'lat': 37.0583, 'lon': 9.2378},
    },
    'Béja': {
      'Béja': {'lat': 36.7256, 'lon': 9.1817},
      'Medjez el-Bab': {'lat': 36.6500, 'lon': 9.6167},
      'Testour': {'lat': 36.5500, 'lon': 9.4500},
      'Nefza': {'lat': 37.0417, 'lon': 9.3167},
    },
    'Jendouba': {
      'Jendouba': {'lat': 36.5011, 'lon': 8.7803},
      'Tabarka': {'lat': 36.9544, 'lon': 8.7581},
      'Aïn Draham': {'lat': 36.7833, 'lon': 8.6833},
      'Ghardimaou': {'lat': 36.4500, 'lon': 8.4333},
      'Fernana': {'lat': 36.7000, 'lon': 8.6333},
    },
    'Le Kef': {
      'Le Kef': {'lat': 36.1675, 'lon': 8.7050},
      'Dahmani': {'lat': 35.9667, 'lon': 8.8167},
      'Tajerouine': {'lat': 35.8917, 'lon': 8.5528},
      'Kalaat Khasba': {'lat': 36.2667, 'lon': 8.7500},
    },
    'Siliana': {
      'Siliana': {'lat': 36.0847, 'lon': 9.3708},
      'Makthar': {'lat': 35.8583, 'lon': 9.2008},
      'Bou Arada': {'lat': 36.3667, 'lon': 9.6167},
      'Kesra': {'lat': 35.8167, 'lon': 9.3667},
    },
    'Kairouan': {
      'Kairouan': {'lat': 35.6781, 'lon': 10.0963},
      'Haffouz': {'lat': 35.6333, 'lon': 9.6833},
      'Sbikha': {'lat': 35.9333, 'lon': 9.8833},
      'Oueslatia': {'lat': 35.8167, 'lon': 9.5667},
      'Chebika': {'lat': 35.8667, 'lon': 10.0167},
    },
    'Kasserine': {
      'Kasserine': {'lat': 35.1672, 'lon': 8.8361},
      'Sbeitla': {'lat': 35.2333, 'lon': 9.1167},
      'Sbiba': {'lat': 35.5333, 'lon': 9.0833},
      'Thala': {'lat': 35.5667, 'lon': 8.6667},
      'Feriana': {'lat': 34.9667, 'lon': 8.5500},
    },
    'Sidi Bouzid': {
      'Sidi Bouzid': {'lat': 35.0381, 'lon': 9.4858},
      'Regueb': {'lat': 34.8667, 'lon': 9.7833},
      'Menzel Bouzaiane': {'lat': 35.0833, 'lon': 9.5833},
      'Meknassy': {'lat': 34.6167, 'lon': 9.6000},
    },
    'Sousse': {
      'Sousse': {'lat': 35.8256, 'lon': 10.6369},
      'M\'saken': {'lat': 35.7292, 'lon': 10.5806},
      'Kalaa Kebira': {'lat': 35.9667, 'lon': 10.5167},
      'Enfidha': {'lat': 36.1406, 'lon': 10.3722},
      'Hammam Sousse': {'lat': 35.8608, 'lon': 10.6003},
    },
    'Monastir': {
      'Monastir': {'lat': 35.7643, 'lon': 10.8113},
      'Ksar Hellal': {'lat': 35.6472, 'lon': 10.8950},
      'Moknine': {'lat': 35.6333, 'lon': 10.9000},
      'Jemmal': {'lat': 35.6261, 'lon': 10.7572},
      'Bekalta': {'lat': 35.6167, 'lon': 11.0000},
    },
    'Mahdia': {
      'Mahdia': {'lat': 35.5047, 'lon': 11.0622},
      'Chebba': {'lat': 35.2372, 'lon': 11.1150},
      'Ksour Essef': {'lat': 35.4167, 'lon': 10.9833},
      'El Jem': {'lat': 35.3000, 'lon': 10.7167},
    },
    'Sfax': {
      'Sfax': {'lat': 34.7406, 'lon': 10.7603},
      'Sakiet Ezzit': {'lat': 34.8000, 'lon': 10.7333},
      'Sakiet Eddaier': {'lat': 34.8167, 'lon': 10.6833},
      'Gremda': {'lat': 34.7500, 'lon': 10.7833},
      'Agareb': {'lat': 34.7500, 'lon': 10.4667},
    },
    'Gabès': {
      'Gabès': {'lat': 33.8815, 'lon': 10.0982},
      'El Hamma': {'lat': 33.8908, 'lon': 9.7986},
      'Mareth': {'lat': 33.6372, 'lon': 10.2925},
      'Matmata': {'lat': 33.5458, 'lon': 9.9656},
      'Menzel El Habib': {'lat': 33.9167, 'lon': 10.0833},
    },
    'Médenine': {
      'Médenine': {'lat': 33.3547, 'lon': 10.5053},
      'Djerba': {'lat': 33.8076, 'lon': 10.8451},
      'Zarzis': {'lat': 33.5039, 'lon': 11.1122},
      'Ben Guerdane': {'lat': 33.1381, 'lon': 11.2194},
    },
    'Tataouine': {
      'Tataouine': {'lat': 32.9297, 'lon': 10.4517},
      'Ghomrassen': {'lat': 33.0667, 'lon': 10.3167},
      'Remada': {'lat': 32.3167, 'lon': 10.3833},
      'Bir Lahmar': {'lat': 32.6667, 'lon': 10.5833},
    },
    'Gafsa': {
      'Gafsa': {'lat': 34.4250, 'lon': 8.7842},
      'El Ksar': {'lat': 34.4167, 'lon': 8.8333},
      'Métlaoui': {'lat': 34.3333, 'lon': 8.4000},
      'Redeyef': {'lat': 34.3833, 'lon': 8.1500},
      'Mdhilla': {'lat': 34.3500, 'lon': 8.6667},
    },
    'Tozeur': {
      'Tozeur': {'lat': 33.9197, 'lon': 8.1344},
      'Nefta': {'lat': 33.8833, 'lon': 7.8833},
      'Degache': {'lat': 33.9833, 'lon': 8.2000},
      'Tameghza': {'lat': 34.4167, 'lon': 7.9167},
    },
    'Kébili': {
      'Kébili': {'lat': 33.7050, 'lon': 8.9697},
      'Douz': {'lat': 33.4667, 'lon': 9.0167},
      'Souk Lahad': {'lat': 33.6333, 'lon': 9.0000},
      'Jemna': {'lat': 33.5667, 'lon': 8.9667},
    },
  };

  // Obtenir toutes les wilayas
  static List<String> getWilayas() {
    return _tunisiaLocations.keys.toList()..sort();
  }

  // Obtenir les villages d'une wilaya
  static List<String> getVillagesByWilaya(String wilaya) {
    return _tunisiaLocations[wilaya]?.keys.toList() ?? [];
  }

  // Obtenir les coordonnées d'un village
  static Map<String, double>? getVillageCoordinates(String wilaya, String village) {
    return _tunisiaLocations[wilaya]?[village];
  }

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

  // Obtenir la météo pour un village spécifique
  Future<WeatherData> getWeatherByVillage(String wilaya, String village) async {
    final coords = getVillageCoordinates(wilaya, village);
    if (coords == null) {
      throw Exception('Village non trouvé: $village dans $wilaya');
    }
    return await getWeatherByCoordinates(coords['lat']!, coords['lon']!);
  }

  // Obtenir la météo pour toutes les villes agricoles principales
  Future<List<WeatherData>> getAgriculturalWeather() async {
    final List<WeatherData> weatherList = [];
    
    // Prendre le premier village (chef-lieu) de chaque wilaya
    for (final wilaya in _tunisiaLocations.entries) {
      try {
        final firstVillage = wilaya.value.entries.first;
        final weather = await getWeatherByCoordinates(
          firstVillage.value['lat']!,
          firstVillage.value['lon']!,
        );
        weatherList.add(weather);
      } catch (e) {
        print('Erreur météo pour ${wilaya.key}: $e');
      }
    }
    return weatherList;
  }

  // Obtenir la météo pour tous les villages d'une wilaya
  Future<List<WeatherData>> getWeatherByWilaya(String wilaya) async {
    final List<WeatherData> weatherList = [];
    final villages = _tunisiaLocations[wilaya];
    
    if (villages == null) {
      throw Exception('Wilaya non trouvée: $wilaya');
    }

    for (final village in villages.entries) {
      try {
        final weather = await getWeatherByCoordinates(
          village.value['lat']!,
          village.value['lon']!,
        );
        weatherList.add(weather);
      } catch (e) {
        print('Erreur météo pour ${village.key}: $e');
      }
    }
    return weatherList;
  }

  Future<WeatherData> getCurrentLocationWeather() async {
    // Par défaut Tunis
    return await getWeatherByCity('Tunis');
  }
}