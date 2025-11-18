import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';

class FarmerRegisterScreen extends StatefulWidget {
  const FarmerRegisterScreen({super.key});

  @override
  State<FarmerRegisterScreen> createState() => _FarmerRegisterScreenState();
}

class _FarmerRegisterScreenState extends State<FarmerRegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  final AuthService _authService = AuthService();

  void _showSnackbar(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red : Colors.green));
  }

  Future<void> _onRegister() async {
    setState(() => _loading = true);
    final result = await _authService.register(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      role: 'farmer',
    );
    setState(() => _loading = false);
    if (!result['success']) {
      _showSnackbar(result['message']?.toString() ?? 'Erreur inscription',
          error: true);
      return;
    }
    _showSnackbar('Compte créé avec succès !');
    Navigator.pop(context); // retour vers login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte Fermier')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nom complet')),
            const SizedBox(height: 12),
            TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                obscureText: true),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : CustomButton(text: 'S\'inscrire', onTap: _onRegister),
          ],
        ),
      ),
    );
  }
}
