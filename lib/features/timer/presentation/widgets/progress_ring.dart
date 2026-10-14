import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:interactive_notifications/core/style/container.dart';
import 'package:interactive_notifications/features/timer/presentation/widgets/timer_display.dart';

class ProgressRingWidget extends StatelessWidget {
  static const double _totalDiameter = 300.0; // including the container
  static const double _padding = 15; // Between progress circle and container

  static const int _secondsForFullRing = 60 * 60; // 1h

  final int secondsPassed;

  const ProgressRingWidget({super.key, required this.secondsPassed});

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final tertiaryColor = Theme.of(context).colorScheme.tertiary;
    double progressValue = secondsPassed <= 0
        ? 0.0
        : ((secondsPassed / _secondsForFullRing) * 1000).round() / 1000;

    return Container(
      width: _totalDiameter,
      height: _totalDiameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        boxShadow: [defaultBoxShadow()],
      ),
      child: CustomPaint(
        painter: _RingPainter(
          progress: progressValue,
          topLeftActiveColor: secondaryColor,
          bottomRightActiveColor: tertiaryColor,
        ),
        child: Center(child: TimerDisplay(secondsPassed: secondsPassed)),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  static const double lineWeight = 20.0;

  /// 0.0 - 1.0
  final double progress;
  final Color topLeftActiveColor;
  final Color bottomRightActiveColor;

  _RingPainter({
    required this.progress,
    required this.topLeftActiveColor,
    required this.bottomRightActiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - lineWeight) / 2 - ProgressRingWidget._padding;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final inactiveRingPaint = Paint()
      ..strokeWidth = lineWeight
      ..style = PaintingStyle.stroke
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.grey.shade200, Colors.grey.shade500],
      ).createShader(rect);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      inactiveRingPaint,
    );

    final activeRingPaint = Paint()
      ..strokeWidth = lineWeight
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [topLeftActiveColor, bottomRightActiveColor],
      ).createShader(rect);

    canvas.drawArc(
      rect,
      3 * math.pi / 2,
      2 * math.pi * progress,
      false,
      activeRingPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
