import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/custom_button.dart';
import '../enterprise/enterprise_role_screen.dart';
import '../farmer/farmer_form_screen.dart';
import '../../presentation/providers/language_provider.dart';
import '../../l10n/app_localizations.dart';
import 'dart:math';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AppLocalizations _l10n;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _animatedBackground() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: WavePainter(_animation.value),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final currentLang = locale.languageCode;

    String welcomeText = {
      'fr': "Bienvenue sur AgroPiquet 🌿🏢",
      'en': "Welcome to AgroPiquet 🌿🏢",
      'ar': "مرحبًا بك في أغروبيكيت 🌿🏢"
    }[currentLang]!;

    String roleText = {
      'fr': "Choisissez votre rôle pour continuer",
      'en': "Choose your role to continue",
      'ar': "اختر دورك للمتابعة"
    }[currentLang]!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Stack(
        children: [
          _animatedBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_animation.value),
                        child: Container(
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
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    welcomeText,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF48D1CC),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    roleText,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.centerRight,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.language, color: Color(0xFF48D1CC)),
                      onSelected: (value) {
                        changeLanguage(ref, value);
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
                        gradientColors: const [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const FarmerFormScreen()),
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
                        gradientColors: const [Color(0xFF2196F3), Color(0xFF64B5F6)],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EnterpriseRoleScreen()),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(
                opacity: value,
                child: Container(
                  width: 200,
                  height: 240,
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
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _animation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, -_animation.value * 0.4),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 100,
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
                                        size: 45,
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
                                            size: 20,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 22,
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
                            const SizedBox(height: 10),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 15,
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
          },
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double offset;
  WavePainter(this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = const Color(0xFF48D1CC).withOpacity(0.3);
    final paint2 = Paint()..color = const Color(0xFF20B2AA).withOpacity(0.2);

    final path1 = Path();
    final path2 = Path();

    path1.moveTo(0, size.height * 0.5);
    for (double i = 0; i <= size.width; i++) {
      path1.lineTo(
          i, size.height * 0.5 + sin((i / size.width * 2 * 3.1415) + offset) * 20);
    }
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();

    path2.moveTo(0, size.height * 0.55);
    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(
          i, size.height * 0.55 + cos((i / size.width * 2 * 3.1415) + offset) * 25);
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => true;
}