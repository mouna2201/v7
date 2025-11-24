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
    // 🔄 Vérifier sur le backend si le formulaire a déjà été complété
    final profile = await _authService.fetchFarmerProfile();

    final hasCompletedForm =
        profile != null && profile['hasCompletedFarmerForm'] == true;

    if (hasCompletedForm) {
      // Essayer de récupérer les données de parcelle depuis le profil
      final String location = profile['parcelLocation'] as String? ?? '';
      final String soilType = profile['soilType'] as String? ?? 'sableux';
      final List<dynamic> cropsRaw = profile['crops'] as List<dynamic>? ?? [];
      final List<String> cropTypes = cropsRaw.map((e) => e.toString()).toList();

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
    }

    // Sinon, afficher le formulaire une première fois
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FarmerFormScreen(farmerName: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF166534),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Connexion Fermier',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFC9E4CA), // vert très clair
              Color(0xFFE8F5E9),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // En-tête avec icône
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA5D6A7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF43A047),
                          ),
                        ),
                        child: const Icon(
                          Icons.agriculture,
                          color: Color(0xFF1B5E20),
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bienvenue 👨‍🌾',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF1B5E20),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Connectez-vous pour accéder à votre plan d\'irrigation et à vos données.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Carte de connexion
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8E9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFBDBDBD),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Color(0xFF1B5E20)),
                          decoration: InputDecoration(
                            labelText: 'Nom',
                            labelStyle: TextStyle(color: Colors.grey.shade700),
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: Color(0xFF388E3C),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF1F8E9),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFBDBDBD),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: primary, width: 1.6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordController,
                          style: const TextStyle(color: Color(0xFF1B5E20)),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            labelStyle: TextStyle(color: Colors.grey.shade700),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Color(0xFF388E3C),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF1F8E9),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFBDBDBD),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: primary, width: 1.6),
                            ),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 20),
                        _loading
                            ? const Center(child: CircularProgressIndicator())
                            : CustomButton(
                                text: 'Se connecter',
                                onTap: _login,
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Lien d'inscription
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FarmerRegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "S'inscrire comme fermier",
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF166534),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Créer un compte Fermier',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFC9E4CA),
              Color(0xFFE8F5E9),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA5D6A7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF43A047),
                          ),
                        ),
                        child: const Icon(
                          Icons.agriculture,
                          color: Color(0xFF1B5E20),
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Créer votre compte',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF1B5E20),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enregistrez un identifiant et un mot de passe pour accéder à votre tableau de bord fermier.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8E9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFBDBDBD),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _name,
                          style: const TextStyle(color: Color(0xFF1B5E20)),
                          decoration: InputDecoration(
                            labelText: 'Nom (identifiant fermier)',
                            labelStyle: TextStyle(color: Colors.grey.shade700),
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: Color(0xFF388E3C),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF1F8E9),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFBDBDBD),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: primary, width: 1.6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _password,
                          style: const TextStyle(color: Color(0xFF1B5E20)),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            labelStyle: TextStyle(color: Colors.grey.shade700),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Color(0xFF388E3C),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF1F8E9),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFBDBDBD),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: primary, width: 1.6),
                            ),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 20),
                        _loading
                            ? const Center(child: CircularProgressIndicator())
                            : CustomButton(
                                text: 'S\'inscrire', onTap: _onRegister),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
