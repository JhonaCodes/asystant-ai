import 'dart:math' as math;
import 'dart:ui';

import 'package:asystant_ai/src/mermaid/mermaid_direction.dart';
import 'package:asystant_ai/src/mermaid/mermaid_node.dart';

/// Size, outline, label position and edge ports of every node shape, from
/// one set of proportions so the layout and the painter agree.
///
/// Lengths scale with `unit`, the node text size relative to 14 px.
abstract final class MermaidShapeGeometry {
  static const double _padX = 14;

  static const double _padY = 9;

  static const double _corner = 5;

  static const double _roundedCorner = 14;

  static const double _subroutineInset = 7;

  static const double _ringGap = 4;

  /// Narrowest a box-like node gets, relative to its height.
  static const double _minAspect = 1.6;

  /// Diamond text sits in this share of the half-width (the rest of the
  /// height): wider than tall reads better than Mermaid's square diamonds.
  static const double _diamondWidthShare = .6;

  /// The box a label of [text] size needs inside [shape].
  static Size boxFor(MermaidNodeShape shape, Size text, double unit) {
    final padX = _padX * unit;
    final padY = _padY * unit;
    final height = text.height + 2 * padY;
    final roomy = math.max(text.width + 2 * padX, height * _minAspect);
    return switch (shape) {
      MermaidNodeShape.rectangle ||
      MermaidNodeShape.rounded => Size(roomy, height),
      MermaidNodeShape.subroutine => Size(
        roomy + 2 * _subroutineInset * unit,
        height,
      ),
      MermaidNodeShape.stadium => Size(
        math.max(text.width + height + 4 * unit, height * _minAspect),
        height,
      ),
      MermaidNodeShape.cylinder => () {
        final rim = _rim(roomy, unit);
        return Size(roomy, height + 3 * rim);
      }(),
      MermaidNodeShape.circle => Size.square(_circleDiameter(text, unit)),
      MermaidNodeShape.doubleCircle => Size.square(
        _circleDiameter(text, unit) + 2 * _ringGap * unit,
      ),
      MermaidNodeShape.diamond => Size(
        (text.width + padX) / _diamondWidthShare,
        (text.height + padY) / (1 - _diamondWidthShare),
      ),
      MermaidNodeShape.hexagon => Size(
        text.width + 2 * padX + height / 2,
        height,
      ),
      MermaidNodeShape.leanRight ||
      MermaidNodeShape.leanLeft => Size(roomy + _skew(height), height),
      MermaidNodeShape.trapezoid || MermaidNodeShape.invertedTrapezoid => Size(
        roomy + 2 * _skew(height),
        height,
      ),
      MermaidNodeShape.asymmetric => Size(roomy + _notch(height), height),
    };
  }

  static double _circleDiameter(Size text, double unit) => math.max(
    math.sqrt(text.width * text.width + text.height * text.height) +
        _padY * unit,
    text.height + 2 * _padY * unit,
  );

  static double _rim(double width, double unit) =>
      (width * .07).clamp(4 * unit, 9 * unit);

  static double _skew(double height) => height * .35;

  static double _notch(double height) => height * .3;

  /// Top-left corner of a label of [text] size inside [box].
  static Offset labelOffset(
    MermaidNodeShape shape,
    Rect box,
    Size text,
    double unit,
  ) {
    final centered = box.center - Offset(text.width / 2, text.height / 2);
    return switch (shape) {
      // Below the cylinder's front rim, above its bottom curve.
      MermaidNodeShape.cylinder => Offset(
        centered.dx,
        centered.dy + _rim(box.width, unit) / 2,
      ),
      MermaidNodeShape.asymmetric => Offset(
        centered.dx + _notch(box.height) / 2,
        centered.dy,
      ),
      _ => centered,
    };
  }

  /// The node's outline, filled and stroked.
  static Path outline(MermaidNodeShape shape, Rect box, double unit) {
    final (left, top, right, bottom) = (
      box.left,
      box.top,
      box.right,
      box.bottom,
    );
    final middle = box.center.dy;
    return switch (shape) {
      MermaidNodeShape.rectangle || MermaidNodeShape.subroutine =>
        Path()..addRRect(
          RRect.fromRectAndRadius(box, Radius.circular(_corner * unit)),
        ),
      MermaidNodeShape.rounded =>
        Path()..addRRect(
          RRect.fromRectAndRadius(
            box,
            Radius.circular(math.min(_roundedCorner * unit, box.height / 2)),
          ),
        ),
      MermaidNodeShape.stadium =>
        Path()..addRRect(
          RRect.fromRectAndRadius(box, Radius.circular(box.height / 2)),
        ),
      MermaidNodeShape.cylinder => _cylinder(box, unit),
      MermaidNodeShape.circle ||
      MermaidNodeShape.doubleCircle => Path()..addOval(box),
      MermaidNodeShape.diamond => _polygon([
        Offset(box.center.dx, top),
        Offset(right, middle),
        Offset(box.center.dx, bottom),
        Offset(left, middle),
      ]),
      MermaidNodeShape.hexagon => _polygon([
        Offset(left + box.height / 4, top),
        Offset(right - box.height / 4, top),
        Offset(right, middle),
        Offset(right - box.height / 4, bottom),
        Offset(left + box.height / 4, bottom),
        Offset(left, middle),
      ]),
      MermaidNodeShape.leanRight => _polygon([
        Offset(left + _skew(box.height), top),
        Offset(right, top),
        Offset(right - _skew(box.height), bottom),
        Offset(left, bottom),
      ]),
      MermaidNodeShape.leanLeft => _polygon([
        Offset(left, top),
        Offset(right - _skew(box.height), top),
        Offset(right, bottom),
        Offset(left + _skew(box.height), bottom),
      ]),
      MermaidNodeShape.trapezoid => _polygon([
        Offset(left + _skew(box.height), top),
        Offset(right - _skew(box.height), top),
        Offset(right, bottom),
        Offset(left, bottom),
      ]),
      MermaidNodeShape.invertedTrapezoid => _polygon([
        Offset(left, top),
        Offset(right, top),
        Offset(right - _skew(box.height), bottom),
        Offset(left + _skew(box.height), bottom),
      ]),
      MermaidNodeShape.asymmetric => _polygon([
        Offset(left, top),
        Offset(right, top),
        Offset(right, bottom),
        Offset(left, bottom),
        Offset(left + _notch(box.height), middle),
      ]),
    };
  }

  /// Lines drawn over the outline: a subroutine's bars, a cylinder's front
  /// rim, a double circle's inner ring. Null for the other shapes.
  static Path? detail(MermaidNodeShape shape, Rect box, double unit) =>
      switch (shape) {
        MermaidNodeShape.subroutine =>
          Path()
            ..moveTo(box.left + _subroutineInset * unit, box.top)
            ..lineTo(box.left + _subroutineInset * unit, box.bottom)
            ..moveTo(box.right - _subroutineInset * unit, box.top)
            ..lineTo(box.right - _subroutineInset * unit, box.bottom),
        MermaidNodeShape.cylinder => () {
          final rim = _rim(box.width, unit);
          return Path()..addArc(
            Rect.fromLTWH(box.left, box.top, box.width, 2 * rim),
            0,
            math.pi,
          );
        }(),
        MermaidNodeShape.doubleCircle =>
          Path()..addOval(box.deflate(_ringGap * unit)),
        _ => null,
      };

  static Path _cylinder(Rect box, double unit) {
    final rim = _rim(box.width, unit);
    return Path()
      ..moveTo(box.left, box.top + rim)
      ..lineTo(box.left, box.bottom - rim)
      ..arcTo(
        Rect.fromLTWH(box.left, box.bottom - 2 * rim, box.width, 2 * rim),
        math.pi,
        -math.pi,
        false,
      )
      ..lineTo(box.right, box.top + rim)
      ..arcTo(
        Rect.fromLTWH(box.left, box.top, box.width, 2 * rim),
        0,
        -math.pi,
        false,
      )
      ..close();
  }

  static Path _polygon(List<Offset> points) => Path()..addPolygon(points, true);

  /// How edges may attach to the sides facing the previous (near) and next
  /// (far) rank: the usable span, and how far inside the box the outline
  /// is at the center of each side.
  static ({double span, double nearInset, double farInset}) ports(
    MermaidNodeShape shape,
    Size box,
    MermaidDirection direction,
    double unit,
  ) {
    final margin = 8 * unit;
    double positive(double value) => math.max(0, value);
    if (direction.isVertical) {
      final span = switch (shape) {
        MermaidNodeShape.rectangle ||
        MermaidNodeShape.subroutine => box.width - 2 * margin,
        MermaidNodeShape.rounded => box.width - 2 * _roundedCorner * unit,
        MermaidNodeShape.stadium => box.width - box.height,
        MermaidNodeShape.hexagon => box.width - box.height / 2 - margin,
        MermaidNodeShape.leanRight ||
        MermaidNodeShape.leanLeft ||
        MermaidNodeShape.trapezoid ||
        MermaidNodeShape.invertedTrapezoid =>
          box.width - 2 * _skew(box.height) - margin,
        MermaidNodeShape.asymmetric =>
          box.width - _notch(box.height) - 2 * margin,
        MermaidNodeShape.cylinder ||
        MermaidNodeShape.circle ||
        MermaidNodeShape.doubleCircle ||
        MermaidNodeShape.diamond => 0.0,
      };
      return (span: positive(span), nearInset: 0, farInset: 0);
    }
    final span = switch (shape) {
      MermaidNodeShape.rectangle ||
      MermaidNodeShape.subroutine => box.height - 2 * margin,
      MermaidNodeShape.rounded => box.height - 2 * _roundedCorner * unit,
      MermaidNodeShape.cylinder => box.height - 4 * _rim(box.width, unit),
      _ => 0.0,
    };
    final (leftInset, rightInset) = switch (shape) {
      MermaidNodeShape.leanRight ||
      MermaidNodeShape.leanLeft ||
      MermaidNodeShape.trapezoid ||
      MermaidNodeShape.invertedTrapezoid => (
        _skew(box.height) / 2,
        _skew(box.height) / 2,
      ),
      MermaidNodeShape.asymmetric => (_notch(box.height), 0.0),
      _ => (0.0, 0.0),
    };
    return direction.isReversed
        ? (span: positive(span), nearInset: rightInset, farInset: leftInset)
        : (span: positive(span), nearInset: leftInset, farInset: rightInset);
  }
}
