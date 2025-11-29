import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../enterprise/enterprise_role_screen.dart';
import '../farmer/farmer_login_screen.dart';
import '../../presentation/providers/language_provider.dart';
import '../../l10n/app_localizations.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  late AppLocalizations _l10n;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _animatedBackground() {
    return Stack(
      children: [
        // Image de fond avec effet d'assombrissement
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final currentLang = locale.languageCode;

    String welcomeText = {
      'fr': "Bienvenue sur AgroPiquet ",
      'en': "Welcome to AgroPiquet ",
      'ar': "مرحبًا بك في أغروبيكيت "
    }[currentLang]!;

    String roleText = {
      'fr': "Choisissez votre rôle pour continuer",
      'en': "Choose your role to continue",
      'ar': "اختر دورك للمتابعة"
    }[currentLang]!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _animatedBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF48D1CC), Color(0xFF20B2AA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF48D1CC).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.eco,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    welcomeText,
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
                  const SizedBox(height: 10),
                  Text(
                    roleText,
                    style: TextStyle(
                      fontSize: 18,
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
                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.centerRight,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.language, color: Colors.white),
                      onSelected: (value) {
                        ref.read(languageProvider.notifier).state =
                            Locale(value);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'fr',
                          child: Text(" Français"),
                        ),
                        const PopupMenuItem(
                          value: 'en',
                          child: Text(" English"),
                        ),
                        const PopupMenuItem(
                          value: 'ar',
                          child: Text(" العربية"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildRoleCard(
                        context: context,
                        icon: Icons.agriculture,
                        secondaryIcon: Icons.eco,
                        title: {
                          'fr': "Fermier",
                          'en': "Farmer",
                          'ar': "فلاح"
                        }[currentLang]!,
                        subtitle: {
                          'fr': "Petit exploitant",
                          'en': "Small farmer",
                          'ar': "مزارع صغير"
                        }[currentLang]!,
                        color: const Color(0xFF4CAF50),
                        gradientColors: const [
                          Color(0xFF4CAF50),
                          Color(0xFF8BC34A)
                        ],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FarmerLoginScreen(),
                          ),
                        ),
                      ),
                      _buildRoleCard(
                        context: context,
                        icon: Icons.business,
                        secondaryIcon: Icons.trending_up,
                        title: {
                          'fr': "Entreprise",
                          'en': "Enterprise",
                          'ar': "شركة"
                        }[currentLang]!,
                        subtitle: {
                          'fr': "Société agricole",
                          'en': "Agricultural company",
                          'ar': "شركة زراعية"
                        }[currentLang]!,
                        color: const Color(0xFF2196F3),
                        gradientColors: const [
                          Color(0xFF2196F3),
                          Color(0xFF64B5F6)
                        ],
                        onTap: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const EnterpriseRoleScreen(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              const begin = Offset(0.0, 1.0);
                              const end = Offset.zero;
                              const curve = Curves.easeOutCirc;

                              var tween = Tween(begin: begin, end: end).chain(
                                CurveTween(curve: curve),
                              );

                              return SlideTransition(
                                position: animation.drive(tween),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required IconData icon,
    required IconData secondaryIcon,
    required String title,
    required String subtitle,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        child: Container(
          width: 140,
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.9),
                blurRadius: 15,
                offset: const Offset(-8, -8),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 25,
                offset: const Offset(5, 5),
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          icon,
                          size: 30,
                          color: Colors.white,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              secondaryIcon,
                              size: 15,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: 1.0,
                        shadows: [
                          Shadow(
                            color: color.withOpacity(0.4),
                            offset: const Offset(3, 3),
                            blurRadius: 6,
                          ),
                          Shadow(
                            color: Colors.white.withOpacity(0.8),
                            offset: const Offset(-1, -1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.8),
                            offset: const Offset(1, 1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => false;
}
