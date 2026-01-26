import 'package:flutter/material.dart';
import 'dart:math' as math;

class HourglassTimer extends StatefulWidget {
  final double progress; // 0.0 to 1.0 (1.0 = finished)
  final double size;
  final Color color;

  const HourglassTimer({
    super.key,
    required this.progress,
    this.size = 200,
    required this.color,
  });

  @override
  State<HourglassTimer> createState() => _HourglassTimerState();
}

class _HourglassTimerState extends State<HourglassTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _HourglassPainter(
            progress: widget.progress,
            color: widget.color,
            rotation: _controller.value *
                2 *
                math.pi, // Rotate mostly just for effect or separate animation
            sandFlow: _controller.value,
          ),
        );
      },
    );
  }
}

class _HourglassPainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0 (Emptying top, filling bottom)
  final Color color;
  final double rotation;
  final double sandFlow;

  _HourglassPainter({
    required this.progress,
    required this.color,
    required this.rotation,
    required this.sandFlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Glass shape path
    final path = Path()
      ..moveTo(w * 0.2, 0)
      ..lineTo(w * 0.8, 0)
      ..quadraticBezierTo(w * 0.8, h * 0.45, cx, h * 0.5)
      ..quadraticBezierTo(w * 0.8, h * 0.55, w * 0.8, h)
      ..lineTo(w * 0.2, h)
      ..quadraticBezierTo(w * 0.2, h * 0.55, cx, h * 0.5)
      ..quadraticBezierTo(w * 0.2, h * 0.45, w * 0.2, 0)
      ..close();

    // Draw Glass Outline
    canvas.drawPath(path, paint);

    // Calculate Sand Levels
    // Top starts full (1.0) and goes to empty (0.0) based on progress
    double topLevel = 1.0 - progress;
    // Bottom starts empty (0.0) and goes to full (1.0) based on progress
    double bottomLevel = progress;

    canvas.save();
    canvas.clipPath(path); // Update: Clip to the hourglass shape

    // Draw Top Sand
    if (topLevel > 0) {
      final topSandHeight = (h / 2) * topLevel;
      final topSandRect =
          Rect.fromLTWH(0, (h / 2) - topSandHeight, w, topSandHeight);
      canvas.drawRect(topSandRect, fillPaint);
    }

    // Draw Bottom Sand
    if (bottomLevel > 0) {
      final bottomSandHeight = (h / 2) * bottomLevel;
      final bottomSandRect =
          Rect.fromLTWH(0, h - bottomSandHeight, w, bottomSandHeight);
      canvas.drawRect(bottomSandRect, fillPaint);
    }

    // Draw Falling Sand (Stream)
    if (progress < 1.0) {
      final streamPaint = Paint()
        ..color = color.withOpacity(0.6)
        ..strokeWidth = 2;
      canvas.drawLine(
          Offset(cx, h / 2),
          Offset(cx, h - ((h / 2) * bottomLevel)),
          streamPaint); // Simple line for now
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.sandFlow != sandFlow;
  }
}
