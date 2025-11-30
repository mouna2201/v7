import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedHumidityCircle extends StatefulWidget {
  final int humidity; // 0–100
  final Color color;  // couleur principale de l'eau
  final Duration duration;

  const AnimatedHumidityCircle({
    super.key,
    required this.humidity,
    required this.color,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<AnimatedHumidityCircle> createState() => _AnimatedHumidityCircleState();
}

class _AnimatedHumidityCircleState extends State<AnimatedHumidityCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clamped = widget.humidity.clamp(0, 100).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 260.0;

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fond blanc en forme de goutte
              ClipPath(
                clipper: _DropClipper(),
                child: Container(
                  color: Colors.white,
                ),
              ),
              // Eau animée
              ClipPath(
                clipper: _DropClipper(),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final t = _controller.value;

                    final waterLevel = height * (1 - clamped / 100);

                    return CustomPaint(
                      size: Size(width, height),
                      painter: _WaterPainter(
                        animationValue: t,
                        waterLevel: waterLevel,
                        color: widget.color,
                      ),
                    );
                  },
                ),
              ),
              // Pourcentage
              Text(
                '${clamped.round()}%',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WaterPainter extends CustomPainter {
  final double animationValue;
  final double waterLevel;
  final Color color;

  _WaterPainter({
    required this.animationValue,
    required this.waterLevel,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final path = Path();
    const waveHeight = 8.0;
    final waveLength = size.width / 1.2;
    final baseY = waterLevel;

    path.moveTo(0, size.height);
    path.lineTo(0, baseY);

    for (double x = 0; x <= size.width; x++) {
      final y = baseY +
          math.sin((x / waveLength * 2 * math.pi) + animationValue * 2 * math.pi) *
              waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Légère surcouche plus claire
    final overlay = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.4);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, baseY),
      overlay,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.waterLevel != waterLevel ||
        oldDelegate.color != color;
  }
}

class _DropClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final width = size.width;
    final height = size.height;

    final path = Path();
    final centerX = width / 2;
    final topY = height * 0.02;   // pointe plus haute
    final bottomY = height * 0.97; // base un peu plus basse

    // Goutte / larme : fine en haut, large et bien arrondie en bas
    path.moveTo(centerX, topY);

    // Côté droit : épaule plus haute et corps étiré
    path.quadraticBezierTo(
      centerX + width * 0.14, height * 0.22,
      centerX + width * 0.26, height * 0.58,
    );
    // Grande courbe de la base (encore plus arrondie)
    path.quadraticBezierTo(
      centerX + width * 0.26, height * 0.96,
      centerX, bottomY,
    );

    // Côté gauche (symétrique)
    path.quadraticBezierTo(
      centerX - width * 0.26, height * 0.96,
      centerX - width * 0.26, height * 0.58,
    );
    path.quadraticBezierTo(
      centerX - width * 0.14, height * 0.22,
      centerX, topY,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _DropClipper oldClipper) => false;
}