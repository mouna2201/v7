import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';

class EnterpriseAddFarmerScreen extends StatefulWidget {
  const EnterpriseAddFarmerScreen({super.key});

  @override
  State<EnterpriseAddFarmerScreen> createState() =>
      _EnterpriseAddFarmerScreenState();
}

class _EnterpriseAddFarmerScreenState extends State<EnterpriseAddFarmerScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  final AuthService _authService = AuthService();

  Future<void> _addFarmer() async {
    setState(() => _loading = true);
    final result = await _authService.register(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      role: 'enterprise_farmer', // rôle fermier entreprise
    );
    setState(() => _loading = false);

    if (!result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Erreur inscription'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Fermier ajouté !'), backgroundColor: Colors.green),
    );
    final dynamic apiUser = result['user'];

    // On s'assure de toujours renvoyer un objet User au tableau de bord
    if (apiUser is User) {
      Navigator.pop(context, apiUser);
    } else if (apiUser is Map<String, dynamic>) {
      Navigator.pop(context, User.fromJson(apiUser));
    } else {
      Navigator.pop(
        context,
        User(
          id: '',
          email: _email.text,
          name: _name.text,
          role: 'enterprise_farmer',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.enterpriseTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ajouter un fermier'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.agriculture,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nouveau fermier',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        "Ajoutez un fermier pour votre entreprise.",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Nom'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        decoration:
                            const InputDecoration(labelText: 'Mot de passe'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),
                      _loading
                          ? const CircularProgressIndicator()
                          : CustomButton(
                              text: 'Créer fermier', onTap: _addFarmer),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
