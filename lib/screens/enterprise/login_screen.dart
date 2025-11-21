import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'enterprise_dashboard_screen.dart';
import 'enterprise_add_farmer_screen.dart';
import 'enterprise_form_screen.dart';
import 'register_screen.dart'; // 👈 ajouté pour l’inscription

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

    // Vérifie si l'utilisateur correspond au rôle admin
    if (widget.role == "admin" && user.role != "admin") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Seul un admin peut se connecter ici"),
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

    // Redirection selon le rôle
    if (widget.role == "admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EnterpriseDashboardScreen()),
      );
    } else {
      // Superviseur : aller directement au formulaire de parcelle
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EnterpriseFormScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.role == "admin";

    // Utiliser le thème entreprise bleu
    final theme = AppTheme.enterpriseTheme;
    final primary = theme.colorScheme.primary;
    final lightBg = theme.scaffoldBackgroundColor;

    return Theme(
      data: theme,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, lightBg], // bleu foncé → bleu très clair
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.business,
                          color: theme.colorScheme.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Entreprise',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 10),
                  Text(
                    "Connexion ${isAdmin ? 'Admin 🧑‍💼' : 'Superviseur 👨‍🌾'}",
                    style: const TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isAdmin
                        ? "Accédez au tableau de bord de votre entreprise"
                        : "Connectez-vous pour gérer vos fermiers",
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Champs Email
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.white),
                      prefixIcon: const Icon(Icons.email, color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  // Champ mot de passe
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      labelText: 'Mot de passe',
                      labelStyle: const TextStyle(color: Colors.white),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 30),

                  _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : CustomButton(
                          text: 'Se connecter',
                          onTap: _login,
                        ),

                  const SizedBox(height: 20),

                  // ✅ bouton S’inscrire (seulement pour Admin)
                  if (isAdmin)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EnterpriseRegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Créer un compte admin",
                        style: TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
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
