class WeatherData {
  final String cityName;
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final double pressure;
  final String description;
  final String main;
  final String icon;
  final double windSpeed;
  final int windDirection;
  final DateTime timestamp;
  final double rainLast1h;
  final double rainLast3h;
  final double snowLast1h;
  final double snowLast3h;

  WeatherData({
    required this.cityName,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.pressure,
    required this.description,
    required this.main,
    required this.icon,
    required this.windSpeed,
    required this.windDirection,
    required this.timestamp,
    this.rainLast1h = 0.0,
    this.rainLast3h = 0.0,
    this.snowLast1h = 0.0,
    this.snowLast3h = 0.0,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>? ?? {};
    final rain = json['rain'] as Map<String, dynamic>? ?? {};
    final snow = json['snow'] as Map<String, dynamic>? ?? {};

    return WeatherData(
      cityName: json['name'] as String,
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      tempMin: (main['temp_min'] as num).toDouble(),
      tempMax: (main['temp_max'] as num).toDouble(),
      humidity: main['humidity'] as int,
      pressure: (main['pressure'] as num).toDouble(),
      description: weather['description'] as String,
      main: weather['main'] as String,
      icon: weather['icon'] as String,
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0.0,
      windDirection: (wind['deg'] as int?) ?? 0,
      timestamp: DateTime.now(),
      rainLast1h: (rain['1h'] as num?)?.toDouble() ?? 0.0,
      rainLast3h: (rain['3h'] as num?)?.toDouble() ?? 0.0,
      snowLast1h: (snow['1h'] as num?)?.toDouble() ?? 0.0,
      snowLast3h: (snow['3h'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Vérifie s'il y a eu de la pluie récemment
  bool get hasRecentRain => rainLast1h > 0 || rainLast3h > 0;

  // Vérifie s'il y a eu de la neige récemment
  bool get hasRecentSnow => snowLast1h > 0 || snowLast3h > 0;

  // Précipitations totales récentes
  double get totalPrecipitation => rainLast1h + rainLast3h + snowLast1h + snowLast3h;

  // Conversion en format pour le plan d'irrigation
  Map<String, dynamic> toIrrigationFormat() {
    return {
      'day': 'Aujourd\'hui',
      'temp': '${temperature.round()}°',
      'min': '${tempMin.round()}°',
      'rain': (totalPrecipitation * 100).round(), // Convertir en pourcentage simulé
      'humidity': humidity,
      'description': description,
      'windSpeed': windSpeed,
    };
  }

  @override
  String toString() {
    return '$cityName: ${temperature.round()}°C, $description, Humidité: $humidity%';
  }
}
