import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import 'enterprise_add_farmer_screen.dart';
import '../../services/mqtt_service.dart'; // NOUVEAU
import '../../models/sensor_data.dart'; // NOUVEAU
import '../../widgets/sensor_card.dart'; // NOUVEAU
import '../../theme/app_theme.dart';

class EnterpriseDashboardScreen extends StatefulWidget {
  const EnterpriseDashboardScreen({super.key});

  @override
  State<EnterpriseDashboardScreen> createState() =>
      _EnterpriseDashboardScreenState();
}

class _EnterpriseDashboardScreenState extends State<EnterpriseDashboardScreen> {
  List<SensorData> _sensorData = []; // NOUVEAU - Données des capteurs
  final MQTTService _mqttService = MQTTService(); // NOUVEAU
  bool _isConnected = false; // NOUVEAU - Statut connexion

  @override
  void initState() {
    super.initState();
    _initMQTT(); // NOUVEAU - Démarrer MQTT
  }

  // NOUVELLE MÉTHODE - Initialiser MQTT
  void _initMQTT() {
    _mqttService.onDataReceived = (SensorData data) {
      setState(() {
        _sensorData.insert(0, data); // Ajouter au début
        if (_sensorData.length > 50) _sensorData.removeLast(); // Limiter à 50
      });
    };

    _mqttService.connect().then((_) {
      setState(() {
        _isConnected = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.enterpriseTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tableau de bord Admin'),
          actions: [
            // NOUVEAU - Indicateur de connexion MQTT
            Icon(
              _isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: _isConnected ? Colors.white : const Color(0xFF40B2B0),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // BOUTON EXISTANT
              CustomButton(
                text: 'Ajouter un fermier',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EnterpriseAddFarmerScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // NOUVEAU - CARTE DE STATUT MQTT
              Card(
                color: _isConnected ? Colors.green[50] : Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _isConnected ? Icons.sensors : Icons.sensors_off,
                        color: _isConnected ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isConnected
                                ? 'Connecté à HiveMQ'
                                : 'Connexion en cours...',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _isConnected
                                ? '${_sensorData.length} données reçues'
                                : 'Attente des données des capteurs',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (!_isConnected)
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _initMQTT,
                          iconSize: 20,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // NOUVEAU - DONNÉES DES CAPTEURS (si disponibles)
              if (_sensorData.isNotEmpty) ...[
                const Text(
                  'Données des Capteurs en Temps Réel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  flex: 2, // Prend plus d'espace que les fermiers
                  child: ListView.builder(
                    itemCount: _sensorData.length,
                    itemBuilder: (context, index) {
                      return SensorCard(sensorData: _sensorData[index]);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),

        // NOUVEAU - BOUTON POUR RAFRAÎCHIR LES DONNÉES
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (!_isConnected) _initMQTT();
          },
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mqttService.disconnect(); // NOUVEAU - Nettoyer la connexion
    super.dispose();
  }
}
