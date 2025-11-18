import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import 'enterprise_add_farmer_screen.dart';
import '../../services/auth_service.dart';
import '../../services/mqtt_service.dart'; // NOUVEAU
import '../../models/user.dart';
import '../../models/sensor_data.dart'; // NOUVEAU
import '../../widgets/sensor_card.dart'; // NOUVEAU
import '../../theme/app_theme.dart';

class EnterpriseDashboardScreen extends StatefulWidget {
  const EnterpriseDashboardScreen({super.key});

  @override
  State<EnterpriseDashboardScreen> createState() => _EnterpriseDashboardScreenState();
}

class _EnterpriseDashboardScreenState extends State<EnterpriseDashboardScreen> {
  List<UserModel> _farmers = [];
  List<SensorData> _sensorData = []; // NOUVEAU - Données des capteurs
  final MQTTService _mqttService = MQTTService(); // NOUVEAU
  bool _isConnected = false; // NOUVEAU - Statut connexion

  @override
  void initState() {
    super.initState();
    _loadFarmers();
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

  Future<void> _loadFarmers() async {
    final users = await AuthService.getAllUsers();
    setState(() {
      _farmers = users.where((u) => u.role == 'enterprise_farmer').toList();
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
              CustomButton(
                text: 'Ajouter un fermier',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
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
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}