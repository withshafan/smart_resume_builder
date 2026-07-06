import 'dart:math';
import 'package:flutter/material.dart';

/// A small radial progress ring showing a score from 0–100.
///
/// Used on [ResumeCard] and [ResumeDetailScreen].
/// Color transitions: red (0–39) → amber (40–69) → green (70–100).
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    this.size = 48,
    this.strokeWidth = 5,
    this.showLabel = true,
  });

  final int score;
  final double size;
  final double strokeWidth;
  final bool showLabel;

  Color get _ringColor {
    if (score >= 70) return const Color(0xFF2E8B57); // success green
    if (score >= 40) return const Color(0xFFD98E2B); // warning amber
    return const Color(0xFFC13B3B); // error red
  }

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0, 100);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: clamped / 100,
              color: _ringColor,
              strokeWidth: strokeWidth,
              trackColor: Theme.of(context).colorScheme.outline.withAlpha(60),
            ),
          ),
          if (showLabel)
            Text(
              '$clamped',
              style: TextStyle(
                fontSize: size * 0.28,
                fontWeight: FontWeight.bold,
                color: _ringColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final double strokeWidth;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // start at top
      2 * pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
