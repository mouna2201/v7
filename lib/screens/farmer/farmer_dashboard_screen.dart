import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/sensor_card.dart';
import '../../presentation/providers/sensor_provider.dart';
import '../providers/weather_dashboard_provider.dart';
import 'weather_dashboard_screen.dart';
import '../../theme/app_theme.dart';

class FarmerDashboardScreen extends ConsumerStatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  ConsumerState<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends ConsumerState<FarmerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les données météo au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(weatherProvider).loadCurrentWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sensorState = ref.watch(sensorProvider);
    final sensors = sensorState.sensors;

    return Theme(
      data: AppTheme.farmerTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Tableau de bord"),
          actions: [
            Icon(
              sensorState.isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: sensorState.isConnected ? const Color(0xFF6FA86F) : Colors.red,
            ),
            const SizedBox(width: 16),
          ],
        ),
      body: Column(
        children: [
          // Section Météo
          Container(
            height: 200,
            margin: const EdgeInsets.all(8),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Météo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WeatherDashboardScreen(),
                              ),
                            );
                          },
                          child: const Text('Voir tout'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final weatherNotifier = ref.watch(weatherProvider);
                          final currentWeather = weatherNotifier.currentWeather;
                          final isLoading = weatherNotifier.isLoading;

                          if (isLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (currentWeather != null) {
                            return Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      currentWeather.cityName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      currentWeather.description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${currentWeather.temperature.round()}°C',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildWeatherInfo(
                                      Icons.water_drop,
                                      '${currentWeather.humidity}%',
                                    ),
                                    _buildWeatherInfo(
                                      Icons.air,
                                      '${currentWeather.windSpeed.toStringAsFixed(1)} m/s',
                                    ),
                                    if (currentWeather.hasRecentRain)
                                      _buildWeatherInfo(
                                        Icons.grain,
                                        '${currentWeather.totalPrecipitation}mm',
                                      ),
                                  ],
                                ),
                              ],
                            );
                          }

                          return const Center(
                            child: Text(
                              'Météo non disponible',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Section Capteurs
          Expanded(
            child: sensors.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          sensorState.isConnected ? Icons.hourglass_empty : Icons.cloud_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          sensorState.isConnected
                              ? "En attente des données..."
                              : "Hors ligne",
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: sensors.length,
                    itemBuilder: (context, index) {
                      return SensorCard(
                        key: ValueKey(sensors[index].deviceId),
                        sensorData: sensors[index],
                      );
                    },
                  ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildWeatherInfo(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}