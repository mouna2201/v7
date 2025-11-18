import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';

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
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un fermier')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nom')),
            TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email')),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : CustomButton(text: 'Créer fermier', onTap: _addFarmer),
          ],
        ),
      ),
    );
  }
}
