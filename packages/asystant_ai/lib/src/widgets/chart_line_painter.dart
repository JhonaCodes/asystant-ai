import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Connects a finite normalized series, preserving the order supplied by the host.
class ChartLinePainter extends CustomPainter {
  const ChartLinePainter({required this.values, required this.color});

  final List<double> values;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..strokeWidth = size.shortestSide * .015;
    if (values.length == 1) {
      canvas.drawCircle(
        Offset(size.width / 2, (1 - values.single) * size.height),
        size.shortestSide * .02,
        stroke,
      );
      return;
    }
    for (var index = 1; index < values.length; index++) {
      canvas.drawLine(
        Offset(
          (index - 1) / (values.length - 1) * size.width,
          (1 - values[index - 1]) * size.height,
        ),
        Offset(
          index / (values.length - 1) * size.width,
          (1 - values[index]) * size.height,
        ),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(ChartLinePainter oldDelegate) =>
      !listEquals(values, oldDelegate.values) || color != oldDelegate.color;
}
