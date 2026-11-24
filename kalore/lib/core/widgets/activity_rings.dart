import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/apple_colors.dart';

/// Authentic Apple Fitness Activity Rings Widget.
/// Features:
/// - Smooth spring-like entry animation on load
/// - Dynamic gradients along each ring's arc
/// - Overlap end-cap drop shadow for tactile physical depth
/// - Automatic proportional stroke width & responsive scaling
class ActivityRings extends StatefulWidget {
  final double calorieProgress; // 0.0 to 1.5
  final double proteinProgress;
  final double carbsProgress;
  final double size;
  final double? strokeWidth;
  final bool animateOnMount;

  const ActivityRings({
    super.key,
    required this.calorieProgress,
    required this.proteinProgress,
    required this.carbsProgress,
    this.size = 140.0,
    this.strokeWidth,
    this.animateOnMount = true,
  });

  @override
  State<ActivityRings> createState() => _ActivityRingsState();
}

class _ActivityRingsState extends State<ActivityRings>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (widget.animateOnMount) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant ActivityRings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.calorieProgress != widget.calorieProgress ||
        oldWidget.proteinProgress != widget.proteinProgress ||
        oldWidget.carbsProgress != widget.carbsProgress) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStroke = widget.strokeWidth ?? (widget.size * 0.082);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _ActivityRingsPainter(
              calorieProgress:
                  widget.calorieProgress.clamp(0.0, 1.5) * _animation.value,
              proteinProgress:
                  widget.proteinProgress.clamp(0.0, 1.5) * _animation.value,
              carbsProgress:
                  widget.carbsProgress.clamp(0.0, 1.5) * _animation.value,
              strokeWidth: effectiveStroke,
            ),
          ),
        );
      },
    );
  }
}

class _ActivityRingsPainter extends CustomPainter {
  final double calorieProgress;
  final double proteinProgress;
  final double carbsProgress;
  final double strokeWidth;

  _ActivityRingsPainter({
    required this.calorieProgress,
    required this.proteinProgress,
    required this.carbsProgress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringSpacing = strokeWidth + (size.width * 0.025);

    // Outer Ring: Calories (Move - Red/Orange)
    final r1 = (size.width / 2) - (strokeWidth / 2);
    _drawRing(
      canvas: canvas,
      center: center,
      radius: r1,
      progress: calorieProgress,
      startColor: AppleColors.calorieOrange,
      endColor: AppleColors.calorieOrangeGlow,
    );

    // Middle Ring: Protein (Exercise - Coral/Pink)
    final r2 = r1 - ringSpacing;
    _drawRing(
      canvas: canvas,
      center: center,
      radius: r2,
      progress: proteinProgress,
      startColor: AppleColors.proteinCoral,
      endColor: AppleColors.proteinCoralGlow,
    );

    // Inner Ring: Carbs (Stand - Warm Yellow)
    final r3 = r2 - ringSpacing;
    _drawRing(
      canvas: canvas,
      center: center,
      radius: r3,
      progress: carbsProgress,
      startColor: AppleColors.carbsYellow,
      endColor: AppleColors.carbsYellowGlow,
    );
  }

  void _drawRing({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double progress,
    required Color startColor,
    required Color endColor,
  }) {
    if (radius <= 0) return;

    // 1. Inactive background track
    final trackPaint = Paint()
      ..color = startColor.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.0) return;

    const startAngle = -math.pi / 2; // Top 12 o'clock
    final sweepAngle = 2 * math.pi * progress;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 2. Active arc with Apple SweepGradient
    final activePaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + 2 * math.pi,
        colors: [startColor, endColor, startColor],
        stops: const [0.0, 0.75, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, activePaint);

    // 3. Apple Tip End-Cap Shadow for tactile depth
    if (progress > 0.05) {
      final endAngle = startAngle + sweepAngle;
      final tipX = center.dx + radius * math.cos(endAngle);
      final tipY = center.dy + radius * math.sin(endAngle);
      final tipCenter = Offset(tipX, tipY);

      // Subtle drop shadow under the tip
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

      canvas.drawCircle(tipCenter, strokeWidth / 2, shadowPaint);

      // Overlap tip circle in endColor
      final tipPaint = Paint()
        ..color = endColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(tipCenter, strokeWidth / 2, tipPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityRingsPainter oldDelegate) {
    return oldDelegate.calorieProgress != calorieProgress ||
        oldDelegate.proteinProgress != proteinProgress ||
        oldDelegate.carbsProgress != carbsProgress ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
