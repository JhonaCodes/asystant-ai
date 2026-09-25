import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Draws a signed bar between the supplied zero baseline and measurement.
class ChartBarPainter extends CustomPainter {
  const ChartBarPainter({
    required this.zero,
    required this.value,
    required this.color,
  });

  final double zero;

  final double value;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTRB(
        math.min(zero, value) * size.width,
        0,
        math.max(zero, value) * size.width,
        size.height,
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(ChartBarPainter oldDelegate) =>
      zero != oldDelegate.zero ||
      value != oldDelegate.value ||
      color != oldDelegate.color;
}
