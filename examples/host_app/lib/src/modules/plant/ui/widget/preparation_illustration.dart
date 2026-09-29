import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:host_app/src/modules/plant/model/plant_enums.dart';

/// A small looping picture of how a preparation is used, for readers who
/// will not read much text: a mug for tea, a dropper for tincture, and so
/// on. Purely decorative; the surrounding text carries the meaning.
class PreparationIllustration extends StatefulWidget {
  const PreparationIllustration({
    super.key,
    required this.scene,
    this.size = 72,
  });

  final PreparationScene scene;
  final double size;

  @override
  State<PreparationIllustration> createState() =>
      _PreparationIllustrationState();
}

class _PreparationIllustrationState extends State<PreparationIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  bool? _reducedMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (reducedMotion == _reducedMotion) return;
    _reducedMotion = reducedMotion;
    switch (reducedMotion) {
      case true:
        _controller
          ..stop()
          ..value = 0.35;
      case false:
        _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: switch (widget.scene) {
            PreparationScene.cup => _CupPainter(
              progress: _controller,
              colors: colors,
            ),
            PreparationScene.compress => _CompressPainter(
              progress: _controller,
              colors: colors,
            ),
            PreparationScene.vapor => _VaporPainter(
              progress: _controller,
              colors: colors,
            ),
            PreparationScene.skin => _SkinPainter(
              progress: _controller,
              colors: colors,
            ),
            PreparationScene.capsule => _CapsulePainter(
              progress: _controller,
              colors: colors,
            ),
            PreparationScene.drops => _DropsPainter(
              progress: _controller,
              colors: colors,
            ),
            PreparationScene.bath => _BathPainter(
              progress: _controller,
              colors: colors,
            ),
          },
        ),
      ),
    );
  }
}

/// Shared math for gentle repeating motion.
abstract final class _Loop {
  /// Value in `[0, 1]` for a phase offset in `[0, 1]`, wrapping around.
  static double phase(double t, double offset) => (t + offset) % 1.0;

  /// Smooth ease in/out for a value already in `[0, 1]`.
  static double ease(double t) => (1 - math.cos(t * math.pi)) / 2;

  /// A sine-driven wobble in `[-1, 1]`.
  static double wobble(double t, {double cycles = 1}) =>
      math.sin(t * math.pi * 2 * cycles);
}

/// Base painter that repaints on every animation tick, driven by
/// [progress], and exposes the current `t` in `[0, 1]`.
abstract class _ScenePainter extends CustomPainter {
  _ScenePainter({required this.progress, required this.colors})
    : super(repaint: progress);

  final Animation<double> progress;
  final ColorScheme colors;

  double get t => progress.value;

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) =>
      oldDelegate.colors != colors;
}

/// A mug of hot tea with rising, fading steam wisps.
class _CupPainter extends _ScenePainter {
  _CupPainter({required super.progress, required super.colors});

  final Paint _mugPaint = Paint()..style = PaintingStyle.fill;
  final Paint _steamPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final mugRect = Rect.fromLTWH(w * 0.22, h * 0.5, w * 0.5, h * 0.32);
    final mugRRect = RRect.fromRectAndCorners(
      mugRect,
      bottomLeft: Radius.circular(w * 0.06),
      bottomRight: Radius.circular(w * 0.06),
    );
    _mugPaint.color = colors.primaryContainer;
    canvas.drawRRect(mugRRect, _mugPaint);

    final handlePath = Path()
      ..moveTo(mugRect.right, mugRect.top + h * 0.05)
      ..quadraticBezierTo(
        mugRect.right + w * 0.16,
        mugRect.top + h * 0.16,
        mugRect.right,
        mugRect.top + h * 0.27,
      );
    _steamPaint
      ..color = colors.primary
      ..strokeWidth = w * 0.04;
    canvas.drawPath(handlePath, _steamPaint);

    for (var i = 0; i < 3; i++) {
      final localT = _Loop.phase(t, i / 3);
      final opacity = math.sin(localT * math.pi).clamp(0.0, 1.0);
      final rise = localT * h * 0.32;
      final wisp = Path();
      final baseX = mugRect.left + mugRect.width * (0.28 + i * 0.22);
      final baseY = mugRect.top - h * 0.06 - rise;
      wisp.moveTo(baseX, baseY);
      for (var s = 1; s <= 4; s++) {
        final sy = baseY - s * h * 0.045;
        final sx = baseX + _Loop.wobble(localT + s * 0.15) * w * 0.05;
        wisp.lineTo(sx, sy);
      }
      _steamPaint
        ..color = colors.onSurfaceVariant.withValues(alpha: opacity * 0.5)
        ..strokeWidth = w * 0.025;
      canvas.drawPath(wisp, _steamPaint);
    }
  }
}

/// A bowl with a folded cloth above it dripping cooled tea back down.
class _CompressPainter extends _ScenePainter {
  _CompressPainter({required super.progress, required super.colors});

  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bowlRect = Rect.fromLTWH(w * 0.2, h * 0.62, w * 0.6, h * 0.24);
    final bowlPath = Path()
      ..moveTo(bowlRect.left, bowlRect.top)
      ..quadraticBezierTo(
        bowlRect.center.dx,
        bowlRect.bottom + h * 0.06,
        bowlRect.right,
        bowlRect.top,
      )
      ..close();
    _fillPaint.color = colors.secondary.withValues(alpha: 0.3);
    canvas.drawPath(bowlPath, _fillPaint);
    _strokePaint
      ..color = colors.secondary
      ..strokeWidth = w * 0.03;
    canvas.drawPath(bowlPath, _strokePaint);

    // Folded cloth: a draped shape narrower and wavy at the bottom, with
    // a fold crease across it — reads as fabric, not a rigid box.
    final clothRect = Rect.fromLTWH(w * 0.28, h * 0.22, w * 0.44, h * 0.22);
    final inset = clothRect.width * 0.08;
    final foldY = clothRect.top + clothRect.height * 0.45;
    final clothPath = Path()
      ..moveTo(clothRect.left, clothRect.top)
      ..lineTo(clothRect.right, clothRect.top)
      ..lineTo(clothRect.right - inset * 0.4, foldY)
      ..lineTo(clothRect.right - inset, clothRect.bottom - h * 0.02)
      ..quadraticBezierTo(
        clothRect.center.dx,
        clothRect.bottom + h * 0.02,
        clothRect.left + inset,
        clothRect.bottom - h * 0.02,
      )
      ..lineTo(clothRect.left + inset * 0.4, foldY)
      ..close();
    _fillPaint.color = colors.tertiary.withValues(alpha: 0.55);
    canvas.drawPath(clothPath, _fillPaint);
    _strokePaint
      ..color = colors.tertiary
      ..strokeWidth = w * 0.025;
    canvas.drawPath(clothPath, _strokePaint);
    canvas.drawLine(
      Offset(clothRect.left + inset * 0.5, foldY),
      Offset(clothRect.right - inset * 0.5, foldY),
      _strokePaint,
    );

    for (var i = 0; i < 2; i++) {
      final localT = _Loop.phase(t, i / 2 + 0.1);
      final startY = clothRect.bottom;
      final endY = bowlRect.top - h * 0.02;
      final dropY = startY + (endY - startY) * localT;
      final opacity = (1 - localT).clamp(0.0, 1.0);
      final dropX = clothRect.left + clothRect.width * (0.4 + i * 0.2);
      _fillPaint.color = colors.onSurfaceVariant.withValues(
        alpha: opacity * 0.6,
      );
      canvas.drawCircle(Offset(dropX, dropY), w * 0.018, _fillPaint);
    }
  }
}

/// A bowl with wide, soft vapor swirls rising and widening.
class _VaporPainter extends _ScenePainter {
  _VaporPainter({required super.progress, required super.colors});

  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bowlRect = Rect.fromLTWH(w * 0.18, h * 0.68, w * 0.64, h * 0.2);
    final bowlPath = Path()
      ..moveTo(bowlRect.left, bowlRect.top)
      ..quadraticBezierTo(
        bowlRect.center.dx,
        bowlRect.bottom + h * 0.08,
        bowlRect.right,
        bowlRect.top,
      )
      ..close();
    _fillPaint.color = colors.secondary.withValues(alpha: 0.3);
    canvas.drawPath(bowlPath, _fillPaint);
    _strokePaint
      ..color = colors.secondary
      ..strokeWidth = w * 0.03;
    canvas.drawPath(bowlPath, _strokePaint);

    for (var i = 0; i < 3; i++) {
      final localT = _Loop.phase(t, i / 3);
      final eased = _Loop.ease(localT);
      final opacity = math.sin(localT * math.pi).clamp(0.0, 1.0);
      final rise = eased * h * 0.5;
      final baseX = bowlRect.center.dx + (i - 1) * w * 0.1;
      final baseY = bowlRect.top - h * 0.02 - rise;
      final swirlWidth = w * (0.1 + eased * 0.12);
      _strokePaint
        ..color = colors.onSurfaceVariant.withValues(alpha: opacity * 0.45)
        ..strokeWidth = w * 0.035;
      final swirl = Path()
        ..moveTo(baseX - swirlWidth, baseY + h * 0.05)
        ..quadraticBezierTo(baseX, baseY - h * 0.06, baseX + swirlWidth, baseY)
        ..quadraticBezierTo(
          baseX,
          baseY - h * 0.14,
          baseX - swirlWidth * 0.7,
          baseY - h * 0.08,
        );
      canvas.drawPath(swirl, _strokePaint);
    }
  }
}

/// A forearm ending in an open hand, with a drop landing and spreading
/// as a small sheen — reads as "apply to the skin" at a glance.
class _SkinPainter extends _ScenePainter {
  _SkinPainter({required super.progress, required super.colors});

  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final palmCenter = Offset(w * 0.5, h * 0.5);
    final handPath = _handSilhouette(w, h);

    _fillPaint.color = colors.tertiary.withValues(alpha: 0.4);
    canvas.drawPath(handPath, _fillPaint);
    _strokePaint
      ..color = colors.tertiary
      ..strokeWidth = w * 0.022;
    canvas.drawPath(handPath, _strokePaint);

    final eased = _Loop.ease(t);
    final dropY = h * 0.05 + eased * (palmCenter.dy - h * 0.13);
    final landed = t > 0.55;

    if (!landed) {
      _fillPaint.color = colors.primary;
      canvas.drawCircle(Offset(palmCenter.dx, dropY), w * 0.03, _fillPaint);
    } else {
      final spreadT = ((t - 0.55) / 0.45).clamp(0.0, 1.0);
      final radius = w * (0.04 + spreadT * 0.12);
      final opacity = (1 - spreadT).clamp(0.0, 1.0);
      _strokePaint
        ..color = colors.primary.withValues(alpha: opacity * 0.7)
        ..strokeWidth = w * 0.018;
      canvas.drawOval(
        Rect.fromCenter(
          center: palmCenter,
          width: radius * 2,
          height: radius * 1.1,
        ),
        _strokePaint,
      );
    }
  }

  /// A single continuous silhouette: forearm, palm, four fingers and a
  /// thumb, built as a union of simple shapes so it reads as one hand.
  Path _handSilhouette(double w, double h) {
    var hand = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.78),
            width: w * 0.26,
            height: h * 0.34,
          ),
          Radius.circular(w * 0.1),
        ),
      );
    final palmRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.5),
      width: w * 0.36,
      height: h * 0.28,
    );
    hand = Path.combine(
      PathOperation.union,
      hand,
      Path()
        ..addRRect(RRect.fromRectAndRadius(palmRect, Radius.circular(w * 0.1))),
    );

    for (var i = 0; i < 4; i++) {
      final fingerX = palmRect.left + palmRect.width * (0.16 + i * 0.23);
      final fingerCenter = Offset(fingerX, palmRect.top - h * 0.03);
      hand = Path.combine(
        PathOperation.union,
        hand,
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: fingerCenter,
              width: w * 0.07,
              height: h * 0.16,
            ),
            Radius.circular(w * 0.035),
          ),
        ),
      );
    }

    final thumbCenter = Offset(
      palmRect.left - w * 0.02,
      palmRect.center.dy + h * 0.02,
    );
    hand = Path.combine(
      PathOperation.union,
      hand,
      Path()..addOval(
        Rect.fromCenter(center: thumbCenter, width: w * 0.12, height: h * 0.09),
      ),
    );

    return hand;
  }
}

/// A two-tone capsule bobbing beside a small glass of water.
class _CapsulePainter extends _ScenePainter {
  _CapsulePainter({required super.progress, required super.colors});

  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final glassRect = Rect.fromLTWH(w * 0.56, h * 0.52, w * 0.26, h * 0.32);
    final glassPath = Path()
      ..moveTo(glassRect.left, glassRect.top)
      ..lineTo(glassRect.left + glassRect.width * 0.1, glassRect.bottom)
      ..lineTo(glassRect.right - glassRect.width * 0.1, glassRect.bottom)
      ..lineTo(glassRect.right, glassRect.top)
      ..close();
    _fillPaint.color = colors.primaryContainer.withValues(alpha: 0.4);
    canvas.drawPath(glassPath, _fillPaint);
    _strokePaint
      ..color = colors.primary
      ..strokeWidth = w * 0.025;
    canvas.drawPath(glassPath, _strokePaint);

    final bob = _Loop.wobble(t) * h * 0.03;
    final tilt = _Loop.wobble(t, cycles: 1) * 0.12;
    canvas.save();
    canvas.translate(w * 0.36, h * 0.5 + bob);
    canvas.rotate(tilt);
    final capsuleRect = Rect.fromCenter(
      center: Offset.zero,
      width: w * 0.3,
      height: w * 0.15,
    );
    final capsuleRRect = RRect.fromRectAndRadius(
      capsuleRect,
      Radius.circular(w * 0.075),
    );
    canvas.save();
    canvas.clipRRect(capsuleRRect);
    _fillPaint.color = colors.secondary;
    canvas.drawRect(
      Rect.fromLTWH(
        capsuleRect.left,
        capsuleRect.top,
        capsuleRect.width / 2,
        capsuleRect.height,
      ),
      _fillPaint,
    );
    _fillPaint.color = colors.tertiary;
    canvas.drawRect(
      Rect.fromLTWH(
        capsuleRect.center.dx,
        capsuleRect.top,
        capsuleRect.width / 2,
        capsuleRect.height,
      ),
      _fillPaint,
    );
    canvas.restore();
    _strokePaint
      ..color = colors.outline
      ..strokeWidth = w * 0.015;
    canvas.drawRRect(capsuleRRect, _strokePaint);
    canvas.restore();
  }
}

/// A dropper above a glass, releasing drops that ripple the water.
class _DropsPainter extends _ScenePainter {
  _DropsPainter({required super.progress, required super.colors});

  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final glassRect = Rect.fromLTWH(w * 0.3, h * 0.58, w * 0.4, h * 0.28);
    final glassPath = Path()
      ..moveTo(glassRect.left, glassRect.top)
      ..lineTo(glassRect.left + glassRect.width * 0.06, glassRect.bottom)
      ..lineTo(glassRect.right - glassRect.width * 0.06, glassRect.bottom)
      ..lineTo(glassRect.right, glassRect.top)
      ..close();
    _fillPaint.color = colors.primaryContainer.withValues(alpha: 0.35);
    canvas.drawPath(glassPath, _fillPaint);
    _strokePaint
      ..color = colors.primary
      ..strokeWidth = w * 0.025;
    canvas.drawPath(glassPath, _strokePaint);

    final dropperBulb = Rect.fromLTWH(w * 0.42, h * 0.1, w * 0.16, h * 0.18);
    _fillPaint.color = colors.tertiary.withValues(alpha: 0.7);
    canvas.drawOval(dropperBulb, _fillPaint);
    _strokePaint
      ..color = colors.tertiary
      ..strokeWidth = w * 0.02;
    canvas.drawOval(dropperBulb, _strokePaint);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.47, dropperBulb.bottom, w * 0.06, h * 0.14),
      _strokePaint,
    );

    for (var i = 0; i < 2; i++) {
      final localT = _Loop.phase(t, i / 2 + 0.15);
      final startY = dropperBulb.bottom + h * 0.14;
      final endY = glassRect.top - h * 0.02;
      if (localT < 0.6) {
        final fallT = localT / 0.6;
        final dropY = startY + (endY - startY) * fallT;
        _fillPaint.color = colors.primary.withValues(alpha: 0.8);
        canvas.drawCircle(Offset(w * 0.5, dropY), w * 0.02, _fillPaint);
      } else {
        final rippleT = (localT - 0.6) / 0.4;
        final radius = w * (0.03 + rippleT * 0.12);
        final opacity = (1 - rippleT).clamp(0.0, 1.0);
        _strokePaint
          ..color = colors.primary.withValues(alpha: opacity * 0.6)
          ..strokeWidth = w * 0.015;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w * 0.5, glassRect.top + h * 0.02),
            width: radius * 2,
            height: radius * 0.7,
          ),
          _strokePaint,
        );
      }
    }
  }
}

/// A bathtub with rising bubbles and a couple of floating leaves.
class _BathPainter extends _ScenePainter {
  _BathPainter({required super.progress, required super.colors});

  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final tubRect = Rect.fromLTWH(w * 0.12, h * 0.58, w * 0.76, h * 0.26);
    final tubRRect = RRect.fromRectAndCorners(
      tubRect,
      bottomLeft: Radius.circular(w * 0.1),
      bottomRight: Radius.circular(w * 0.1),
      topLeft: Radius.circular(w * 0.03),
      topRight: Radius.circular(w * 0.03),
    );
    _fillPaint.color = colors.primaryContainer.withValues(alpha: 0.45);
    canvas.drawRRect(tubRRect, _fillPaint);
    _strokePaint
      ..color = colors.primary
      ..strokeWidth = w * 0.03;
    canvas.drawRRect(tubRRect, _strokePaint);

    for (var i = 0; i < 2; i++) {
      final localT = _Loop.phase(t, i / 2);
      final leafX = tubRect.left + tubRect.width * (0.3 + i * 0.4);
      final bob = _Loop.wobble(localT, cycles: 1) * h * 0.015;
      _fillPaint.color = colors.tertiary.withValues(alpha: 0.8);
      final leaf = Path()
        ..moveTo(leafX - w * 0.03, tubRect.top + bob)
        ..quadraticBezierTo(
          leafX,
          tubRect.top - h * 0.02 + bob,
          leafX + w * 0.03,
          tubRect.top + bob,
        )
        ..quadraticBezierTo(
          leafX,
          tubRect.top + h * 0.02 + bob,
          leafX - w * 0.03,
          tubRect.top + bob,
        )
        ..close();
      canvas.drawPath(leaf, _fillPaint);
    }

    for (var i = 0; i < 3; i++) {
      final localT = _Loop.phase(t, i / 3 + 0.2);
      final eased = _Loop.ease(localT);
      final opacity = math.sin(localT * math.pi).clamp(0.0, 1.0);
      final rise = eased * h * 0.4;
      final bubbleX =
          tubRect.left +
          tubRect.width * (0.2 + i * 0.3) +
          _Loop.wobble(localT + i) * w * 0.02;
      final bubbleY = tubRect.top - rise;
      _strokePaint
        ..color = colors.onSurfaceVariant.withValues(alpha: opacity * 0.5)
        ..strokeWidth = w * 0.015;
      canvas.drawCircle(
        Offset(bubbleX, bubbleY),
        w * (0.02 + eased * 0.015),
        _strokePaint,
      );
    }
  }
}
