import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import '../../providers/parcel_provider.dart';
import './farmer_form_screen.dart';
import './irrigation_plan_screen.dart';
import '../../presentation/providers/language_provider.dart';
import './register_screen.dart';
import '../welcome/welcome_screen.dart';

class FarmerLoginScreen extends ConsumerStatefulWidget {
  const FarmerLoginScreen({super.key});

  @override
  ConsumerState<FarmerLoginScreen> createState() => _FarmerLoginScreenState();
}

class _FarmerLoginScreenState extends ConsumerState<FarmerLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  final AuthService _authService = AuthService();

  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // Pour la gestion de la langue
  late String currentLang;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final loginResult = await _authService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      setState(() => _loading = false);

      if (!loginResult['success']) {
        if (mounted) {
          // Message d'erreur localisé
          String errorMessage = {
            'fr': 'Nom d\'utilisateur ou mot de passe incorrect',
            'en': 'Incorrect username or password',
            'ar': 'اسم المستخدم أو كلمة المرور غير صحيحة',
          }[currentLang]!;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      if (mounted) {
        final user = loginResult['user'];
        final String farmerName = (user is Map && user['name'] is String)
            ? user['name'] as String
            : '';

        // Vérifier si le formulaire fermier est déjà complété
        final profile = await _authService.fetchFarmerProfile();
        final bool hasCompletedForm =
            profile != null && profile['hasCompletedFarmerForm'] == true;

        if (!hasCompletedForm) {
          // Première fois : afficher le formulaire complet
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FarmerFormScreen(
                farmerName: farmerName,
              ),
            ),
          );
        } else {
          // Profil déjà rempli : aller directement au plan d'irrigation
          final String location = profile['parcelLocation'].toString();
          final String soilType = profile['soilType'].toString();
          final List<dynamic> cropsDynamic = profile['crops'] as List<dynamic>;
          final List<String> cropTypes =
              cropsDynamic.map((e) => e.toString()).toList();
          final num areaNum = profile['areaM2'] as num;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => IrrigationPlanScreen(
                location: location,
                soilType: soilType,
                cropTypes: cropTypes,
                areaM2: areaNum.toDouble(),
                farmerName: farmerName,
                farmerAddress: profile['farmerAddress'].toString(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        // Message d'erreur générique localisé
        String errorMessage = {
          'fr': 'Une erreur est survenue. Veuillez réessayer.',
          'en': 'An error occurred. Please try again.',
          'ar': 'حدث خطأ. يرجى المحاولة مرة أخرى.',
        }[currentLang]!;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        // Image farmer.png en arrière-plan principal
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/farmer.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(
                    0.3), // Assombrir l'image pour mieux voir le texte
                BlendMode.darken,
              ),
            ),
          ),
        ),

        // Overlay gradient pour améliorer la lisibilité
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0F4C3A).withOpacity(0.7),
                Color(0xFF1B5E3E).withOpacity(0.8),
                Color(0xFF2E7D32).withOpacity(0.9),
              ],
            ),
          ),
        ),

        // Effets de particules flottantes
        Positioned.fill(
          child: CustomPaint(
            painter: _BackgroundPainter(),
          ),
        ),

        // Éléments décoratifs
        Positioned(
          top: -50,
          right: -30,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),

        Positioned(
          bottom: -80,
          left: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.03),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Récupérer la langue actuelle
    final locale = ref.watch(languageProvider);
    currentLang = locale.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    // Textes localisés
    final Map<String, String> loginTexts = {
      'fr': {
        'title': 'Espace Fermier',
        'subtitle': 'Connectez-vous et gérez vos parcelles',
        'username': 'Nom d\'utilisateur',
        'password': 'Mot de passe',
        'login': 'Se connecter',
        'forgot': 'Mot de passe oublié ?',
        'noAccount': 'Pas encore de compte ? S\'inscrire',
      },
      'en': {
        'title': 'Farmer Space',
        'subtitle': 'Log in and manage your parcels',
        'username': 'Username',
        'password': 'Password',
        'login': 'Log In',
        'forgot': 'Forgot password?',
        'noAccount': 'No account yet? Sign up',
      },
      'ar': {
        'title': 'مساحة المزارع',
        'subtitle': 'تسجيل الدخول وإدارة قطع الأراضي الخاصة بك',
        'username': 'اسم المستخدم',
        'password': 'كلمة المرور',
        'login': 'تسجيل الدخول',
        'forgot': 'نسيت كلمة المرور؟',
        'noAccount': 'ليس لديك حساب؟ سجل الآن',
      },
    }[currentLang]!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Arrière-plan avec image et effet d'assombrissement
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.4),
                BlendMode.darken,
              ),
              child: Image.asset(
                'assets/images/farmer.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Animation des vagues
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: WavePainter(_animation.value),
                );
              },
            ),
          ),

          // Bouton de sortie flottant
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: 3,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    print(' BOUTON CLIQUÉ - INK WELL DETECTÉ ');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Bouton cliqué! Navigation vers Welcome...'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );

                    // Navigation simple
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WelcomeScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.home,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Contenu principal
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Logo et titre avec animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF4CAF50).withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.agriculture,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'AgroPiquet',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.7),
                                  blurRadius: 10,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loginTexts['subtitle']!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.7),
                                  blurRadius: 5,
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Formulaire de connexion
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value * 0.8),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Text(
                                loginTexts['title']!,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Champ nom d'utilisateur
                              TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: loginTexts['username'],
                                  prefixIcon: const Icon(Icons.person,
                                      color: Color(0xFF4CAF50)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 20),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre nom d\'utilisateur';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // Champ mot de passe
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: loginTexts['password'],
                                  prefixIcon: const Icon(Icons.lock,
                                      color: Color(0xFF4CAF50)),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 20),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre mot de passe';
                                  }
                                  if (value.length < 6) {
                                    return 'Le mot de passe doit contenir au moins 6 caractères';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 24),

                              // Bouton de connexion
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4CAF50),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 5,
                                    shadowColor: const Color(0xFF4CAF50)
                                        .withOpacity(0.5),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Text(
                                          loginTexts['login']!,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Lien mot de passe oublié
                              TextButton(
                                onPressed: () {
                                  // TODO: Implémenter la réinitialisation du mot de passe
                                },
                                child: Text(
                                  loginTexts['forgot']!,
                                  style: const TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Lien vers l'inscription
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FarmerRegisterScreen(),
                        ),
                      );
                    },
                    child: Text(
                      loginTexts['noAccount']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 5,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;

  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Dessiner des cercles décoratifs
    for (int i = 0; i < 8; i++) {
      final x = size.width * (0.1 + 0.8 * (i / 7));
      final y = size.height * (0.2 + 0.6 * ((i * 0.7) % 1));
      final radius = 20 + 30 * (i % 3);

      canvas.drawCircle(
        Offset(x, y),
        radius.toDouble(),
        paint,
      );
    }

    // Dessiner des motifs de vague subtils avec animation
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height * 0.8);

    // Animation de la vague basée sur animationValue
    for (double i = 0; i <= size.width; i += 10) {
      path.lineTo(
        i,
        size.height * 0.8 + sin((i + animationValue * 10) / 50) * 10,
      );
    }

    // Dessiner la vague
    canvas.drawPath(path, wavePaint);

    // Ajouter un effet de réflexion
    final reflectionPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final reflectionPath = Path();
    reflectionPath.moveTo(0, size.height * 0.85);

    for (double i = 0; i <= size.width; i += 15) {
      reflectionPath.lineTo(
        i,
        size.height * 0.85 + sin((i - animationValue * 8) / 40) * 5,
      );
    }

    canvas.drawPath(reflectionPath, reflectionPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Dessiner des cercles décoratifs
    for (int i = 0; i < 8; i++) {
      final x = size.width * (0.1 + 0.8 * (i / 7));
      final y = size.height * (0.2 + 0.6 * ((i * 0.7) % 1));
      final radius = 20 + 30 * (i % 3);

      canvas.drawCircle(
        Offset(x, y),
        radius.toDouble(),
        paint,
      );
    }

    // Dessiner des motifs de vague subtils
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    for (double i = 0; i <= size.width; i += 10) {
      path.lineTo(
        i,
        size.height * 0.8 + sin(i / 50) * 15,
      );
    }
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
