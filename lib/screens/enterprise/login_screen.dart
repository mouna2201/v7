import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'enterprise_dashboard_screen.dart';
import 'enterprise_add_farmer_screen.dart';
import 'enterprise_form_screen.dart';
import '../farmer/irrigation_plan_screen.dart';
import 'enterprise_role_screen.dart';
import 'register_screen.dart'; // Import de l'écran d'inscription entreprise

class LoginScreen extends StatefulWidget {
  final String role; // "admin" ou "superviseur"
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  final AuthService _authService = AuthService();

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final result = await _authService.login(email: email, password: password);

    setState(() => _loading = false);

    if (!result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email ou mot de passe incorrect'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = result['user'];

    // Vérifie si l'utilisateur correspond au rôle cible
    if (widget.role == "admin" && user.role != "admin") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Seul un admin peut se connecter ici"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.role == "superviseur" && user.role != "farmer") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Seuls les comptes fermier/superviseur créés par l'admin peuvent se connecter ici"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final primary = Theme.of(context).colorScheme.primary;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bienvenue ${widget.role == "admin" ? "👨‍💼 Admin" : "👨‍🌾 Superviseur"} !',
        ),
        backgroundColor: primary,
      ),
    );

    // Redirection selon le rôle depuis l'écran de login
    if (widget.role == "admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EnterpriseDashboardScreen()),
      );
    } else {
      // Superviseur : charger les données de parcelle associées au compte fermier
      Map<String, dynamic>? profile;
      try {
        profile = await _authService.fetchFarmerProfile();
      } catch (_) {
        profile = null;
      }

      final location = (profile?['parcelLocation'] as String?)?.trim();
      final soilType = (profile?['soilType'] as String?)?.trim();
      final cropsDynamic = profile?['crops'];
      final areaNum = profile?['areaM2'] as num?;

      List<String> crops = [];
      if (cropsDynamic is List) {
        crops = cropsDynamic.whereType<String>().toList();
      } else if (cropsDynamic is String) {
        crops = cropsDynamic
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      // Si le profil n'est pas correctement configuré, on ne veut PAS ouvrir un plan par défaut
      if (location == null ||
          location.isEmpty ||
          soilType == null ||
          soilType.isEmpty ||
          crops.isEmpty ||
          areaNum == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "Aucune parcelle configurée pour ce superviseur. Demandez à l'admin de définir la parcelle."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => IrrigationPlanScreen(
            location: location,
            soilType: soilType,
            cropTypes: crops,
            areaM2: areaNum.toDouble(),
            isSupervisor: true,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.enterpriseTheme;
    final primary = theme.colorScheme.primary;
    final lightBg = theme.scaffoldBackgroundColor;

    final bool isAdmin = widget.role == "admin";

    if (isAdmin) {
      return Theme(
        data: theme,
        child: Scaffold(
          backgroundColor: lightBg,
          appBar: AppBar(
            backgroundColor: Colors.blue, // Changé en bleu pour l'admin
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            centerTitle: true,
            title: const Text(
              'Connexion Admin',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.withOpacity(0.15), // Changé en bleu pour l'admin
                  lightBg,
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue), // Changé en bleu pour l'admin
                            ),
                            child: Icon(
                              Icons.admin_panel_settings,
                              color: Colors.blue, // Changé en bleu pour l'admin
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bienvenue Admin',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.blue, // Changé en bleu pour l'admin
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Connectez-vous pour gérer les fermiers et vos exploitations.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade300),
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
                              controller: _emailController,
                              style: const TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle:
                                    TextStyle(color: Colors.grey.shade700),
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Colors.blue, // Changé en bleu pour l'admin
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.blue, // Changé en bleu pour l'admin
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                labelStyle:
                                    TextStyle(color: Colors.grey.shade700),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: Colors.blue, // Changé en bleu pour l'admin
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.blue, // Changé en bleu pour l'admin
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _loading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : Column(
                                    children: [
                                      CustomButton(
                                        text: 'Se connecter',
                                        onTap: _login,
                                      ),
                                      const SizedBox(height: 12),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EnterpriseRegisterScreen(),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Pas encore de compte ? S\'inscrire',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Écran superviseur (par défaut)
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: lightBg,
        appBar: AppBar(
          backgroundColor: primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: const Text(
            'Connexion Superviseur',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primary.withOpacity(0.15),
                lightBg,
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primary),
                          ),
                          child: Icon(
                            Icons.supervisor_account,
                            color: primary,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bienvenue Superviseur',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Connectez-vous pour suivre les fermiers et leurs parcelles.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade300),
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
                            controller: _emailController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle:
                                  TextStyle(color: Colors.grey.shade700),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: primary,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: primary,
                                  width: 1.6,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              labelStyle:
                                  TextStyle(color: Colors.grey.shade700),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: primary,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: primary,
                                  width: 1.6,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _loading
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : Column(
                                  children: [
                                    CustomButton(
                                      text: 'Se connecter',
                                      onTap: _login,
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EnterpriseRegisterScreen(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Pas encore de compte ? S\'inscrire',
                                        style: TextStyle(
                                          color: primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
