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
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
<<<<<<< HEAD
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Text(
                'Portail Admin Entreprise',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Gérez vos fermiers depuis un tableau de bord simple et moderne.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Bouton principal pour ajouter un fermier
=======
            children: [
              // BOUTON EXISTANT
>>>>>>> 589f17696b050f08cbb08b4626e2e71395d23c2e
              CustomButton(
                text: 'Ajouter un fermier',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
<<<<<<< HEAD
                      builder: (_) => const EnterpriseAddFarmerScreen(),
                    ),
                  );
                  _loadFarmers();
                },
              ),
              const SizedBox(height: 24),

              // Liste simplifiée des fermiers
              Expanded(
                child: _farmers.isEmpty
                    ? const Center(
                        child: Text('Aucun fermier enregistré pour le moment'),
                      )
                    : ListView.builder(
                        itemCount: _farmers.length,
                        itemBuilder: (context, index) {
                          final farmer = _farmers[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(farmer.name),
                            subtitle: Text(farmer.email),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
=======
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
>>>>>>> 589f17696b050f08cbb08b4626e2e71395d23c2e
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
