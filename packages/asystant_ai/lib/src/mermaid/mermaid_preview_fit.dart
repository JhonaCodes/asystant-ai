import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// How a diagram is shown inside a message: scaled down to the width it
/// has, never below [minScale] so its text stays legible, and clipped to
/// the space it gets beyond that.
@immutable
class MermaidPreviewFit {
  const MermaidPreviewFit({
    required this.scale,
    required this.size,
    required this.clipsWidth,
    required this.clipsHeight,
  });

  /// Fits a diagram of [scene] size into [maxWidth] × [maxHeight].
  factory MermaidPreviewFit.of(
    Size scene, {
    required double maxWidth,
    required double maxHeight,
    double minScale = defaultMinScale,
  }) {
    final widthScale = maxWidth.isFinite && scene.width > 0
        ? maxWidth / scene.width
        : 1.0;
    final scale = widthScale.clamp(minScale, 1.0);
    final scaled = scene * scale;
    final size = Size(
      math.max(0, math.min(scaled.width, maxWidth)),
      math.max(0, math.min(scaled.height, maxHeight)),
    );
    return MermaidPreviewFit(
      scale: scale,
      size: size,
      clipsWidth: scaled.width > size.width + .5,
      clipsHeight: scaled.height > size.height + .5,
    );
  }

  /// Below this a diagram's text is too small to read in a message; what
  /// does not fit is clipped, and the full view shows it.
  static const double defaultMinScale = .6;

  /// Applied to the scene's coordinates.
  final double scale;

  /// The part of the scaled diagram that is shown.
  final Size size;

  /// Part of the right side is cut off.
  final bool clipsWidth;

  /// Part of the bottom is cut off.
  final bool clipsHeight;

  @override
  bool operator ==(Object other) =>
      other is MermaidPreviewFit &&
      scale == other.scale &&
      size == other.size &&
      clipsWidth == other.clipsWidth &&
      clipsHeight == other.clipsHeight;

  @override
  int get hashCode => Object.hash(scale, size, clipsWidth, clipsHeight);
}
