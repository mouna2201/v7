import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import 'enterprise_add_farmer_screen.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';

class EnterpriseDashboardScreen extends StatefulWidget {
  const EnterpriseDashboardScreen({super.key});

  @override
  State<EnterpriseDashboardScreen> createState() =>
      _EnterpriseDashboardScreenState();
}

class _EnterpriseDashboardScreenState extends State<EnterpriseDashboardScreen> {
  List<User> _farmers = [];

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
            children: [
              // BOUTON EXISTANT
              CustomButton(
                text: 'Ajouter un fermier',
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EnterpriseAddFarmerScreen()),
                  );

                  if (result is User) {
                    setState(() {
                      _farmers.add(result);
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _farmers.isEmpty
                    ? const Center(
                        child: Text('Aucun fermier pour le moment'),
                      )
                    : ListView.builder(
                        itemCount: _farmers.length,
                        itemBuilder: (context, index) {
                          final farmer = _farmers[index];
                          return ListTile(
                            leading: const Icon(Icons.person),
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
