import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/farmer/weather_dashboard_screen.dart';

/// Exemple d'intégration du dashboard météo dans une application
class WeatherDashboardExample extends ConsumerWidget {
  const WeatherDashboardExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemple Dashboard Météo'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard Météo Intégré',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cet exemple montre comment intégrer le dashboard météo avec l\'API OpenWeatherMap dans votre application agricole.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            // Options de navigation
            Card(
              child: ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard Météo Complet'),
                subtitle: const Text('Affiche toutes les zones agricoles et météo détaillée'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WeatherDashboardScreen(),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fonctionnalités',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(Icons.cloud, 'Connexion API OpenWeatherMap'),
                    _buildFeatureItem(Icons.location_city, '8 villes agricoles tunisiennes'),
                    _buildFeatureItem(Icons.thermostat, 'Température en temps réel'),
                    _buildFeatureItem(Icons.water_drop, 'Humidité et précipitations'),
                    _buildFeatureItem(Icons.air, 'Vitesse et direction du vent'),
                    _buildFeatureItem(Icons.refresh, 'Actualisation automatique'),
                    _buildFeatureItem(Icons.error, 'Gestion des erreurs'),
                    _buildFeatureItem(Icons.storage, 'Cache des données'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Villes Disponibles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Tunis, Sfax, Sousse, Kairouan, Bizerte, Gabès, Ariana, Monastir'),
                    const SizedBox(height: 8),
                    Text(
                      'Coordonnées préconfigurées pour les zones agricoles importantes de la Tunisie',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
