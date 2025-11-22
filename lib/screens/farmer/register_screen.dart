import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import 'farmer_form_screen.dart';
import 'irrigation_plan_screen.dart';

class FarmerRegisterScreen extends StatefulWidget {
  const FarmerRegisterScreen({super.key});

  @override
  State<FarmerRegisterScreen> createState() => _FarmerRegisterScreenState();
}

class FarmerLoginScreen extends StatefulWidget {
  const FarmerLoginScreen({super.key});

  @override
  State<FarmerLoginScreen> createState() => _FarmerLoginScreenState();
}

class _FarmerLoginScreenState extends State<FarmerLoginScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  final AuthService _authService = AuthService();

  Future<void> _login() async {
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    // Utilise le même email technique que pour l’inscription
    final String technicalEmail =
        '${name.toLowerCase().replaceAll(' ', '_')}@farmer.local';

    final result = await _authService.login(
      email: technicalEmail,
      password: password,
    );

    setState(() => _loading = false);

    if (!result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(result['message']?.toString() ?? 'Identifiants incorrects'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = result['user'];
    if (user.role != 'farmer') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seul un compte fermier peut se connecter ici'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bienvenue 👨‍🌾 Fermier !'),
        backgroundColor: Colors.green,
      ),
    );

    // Vérifier s'il existe déjà un plan d'irrigation pour ce fermier
    final prefs = await SharedPreferences.getInstance();
    final normalizedName = name.toLowerCase().replaceAll(' ', '_');
    final planKey = 'farmer_plan_'
        '$normalizedName';
    final savedPlanJson = prefs.getString(planKey);

    if (savedPlanJson != null) {
      try {
        final Map<String, dynamic> plan =
            jsonDecode(savedPlanJson) as Map<String, dynamic>;
        final String location = plan['location'] as String? ?? '';
        final String soilType = plan['soilType'] as String? ?? 'sableux';
        final List<dynamic> cropsRaw = plan['crops'] as List<dynamic>? ?? [];
        final List<String> cropTypes =
            cropsRaw.map((e) => e.toString()).toList();

        if (location.isNotEmpty && cropTypes.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => IrrigationPlanScreen(
                location: location,
                soilType: soilType,
                cropTypes: cropTypes,
              ),
            ),
          );
          return;
        }
      } catch (_) {
        // en cas de problème de parsing, on retombe sur le formulaire
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FarmerFormScreen(farmerName: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion Fermier'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
                    text: 'Se connecter',
                    onTap: _login,
                  ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FarmerRegisterScreen(),
                  ),
                );
              },
              child: const Text("S'inscrire comme fermier"),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmerRegisterScreenState extends State<FarmerRegisterScreen> {
  final _name = TextEditingController();
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

    final String name = _name.text.trim();
    final String password = _password.text.trim();

    // Génère un email technique à partir du nom, car l’API backend demande un email
    final String technicalEmail =
        '${name.toLowerCase().replaceAll(' ', '_')}@farmer.local';

    final result = await _authService.register(
      name: name,
      email: technicalEmail,
      password: password,
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
              decoration:
                  const InputDecoration(labelText: 'Nom (identifiant fermier)'),
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
                : CustomButton(text: 'S\'inscrire', onTap: _onRegister),
          ],
        ),
      ),
    );
  }
}
