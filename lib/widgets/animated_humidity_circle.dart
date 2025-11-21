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

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cercle blanc de fond
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          // Eau animée
          ClipOval(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value;
                const height = 140.0;
                final waterLevel = height * (1 - clamped / 100);

                return CustomPaint(
                  size: const Size(140, 140),
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