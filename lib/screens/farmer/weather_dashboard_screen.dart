import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/weather_data.dart';
import '../providers/weather_dashboard_provider.dart';

class WeatherDashboardScreen extends ConsumerStatefulWidget {
  const WeatherDashboardScreen({super.key});

  @override
  ConsumerState<WeatherDashboardScreen> createState() => _WeatherDashboardScreenState();
}

class _WeatherDashboardScreenState extends ConsumerState<WeatherDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les données météo au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(weatherProvider).refreshAllWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    final weatherNotifier = ref.watch(weatherProvider);
    final currentWeather = weatherNotifier.currentWeather;
    final agriculturalWeather = weatherNotifier.agriculturalWeather;
    final isLoading = weatherNotifier.isLoading;
    final error = weatherNotifier.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Météo'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(weatherProvider).refreshAllWeather();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(weatherProvider).refreshAllWeather(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Météo actuelle
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (error.isNotEmpty)
                _buildErrorCard(error)
              else if (currentWeather != null)
                _buildCurrentWeatherCard(currentWeather),

              const SizedBox(height: 24),

              // Section météo agricole
              const Text(
                'Météo des Zones Agricoles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              if (agriculturalWeather.isEmpty && !isLoading)
                const Center(
                  child: Text(
                    'Aucune donnée météo agricole disponible',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                _buildAgriculturalWeatherGrid(agriculturalWeather),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: TextStyle(color: Colors.red.shade600),
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(weatherProvider).refreshAllWeather();
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherCard(WeatherData weather) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade600,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.cityName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      weather.description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${weather.temperature.round()}°C',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Ressentie ${weather.feelsLike.round()}°C',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherDetail(
                  Icons.water_drop,
                  'Humidité',
                  '${weather.humidity}%',
                  Colors.white70,
                ),
                _buildWeatherDetail(
                  Icons.air,
                  'Vent',
                  '${weather.windSpeed.toStringAsFixed(1)} m/s',
                  Colors.white70,
                ),
                _buildWeatherDetail(
                  Icons.thermostat,
                  'Min/Max',
                  '${weather.tempMin.round()}°/${weather.tempMax.round()}°',
                  Colors.white70,
                ),
                if (weather.hasRecentRain)
                  _buildWeatherDetail(
                    Icons.grain,
                    'Pluie',
                    '${weather.totalPrecipitation}mm',
                    Colors.lightBlueAccent,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAgriculturalWeatherGrid(List<WeatherData> weatherList) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: weatherList.length,
      itemBuilder: (context, index) {
        final weather = weatherList[index];
        return _buildAgriculturalWeatherCard(weather);
      },
    );
  }

  Widget _buildAgriculturalWeatherCard(WeatherData weather) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              weather.cityName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${weather.temperature.round()}°C',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    weather.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniDetail(Icons.water_drop, '${weather.humidity}%'),
                _buildMiniDetail(Icons.air, '${weather.windSpeed.toStringAsFixed(1)}m/s'),
                if (weather.hasRecentRain)
                  _buildMiniDetail(Icons.grain, '${weather.totalPrecipitation}mm'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniDetail(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
