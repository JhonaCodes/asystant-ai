import 'package:flutter/material.dart';

/// Colors a diagram is drawn with, derived from the host's color scheme so
/// it reads in light and dark themes alike.
@immutable
class MermaidPalette {
  const MermaidPalette({
    required this.background,
    required this.nodeFill,
    required this.nodeStroke,
    required this.decisionFill,
    required this.decisionStroke,
    required this.text,
    required this.edge,
    required this.labelFill,
    required this.labelText,
    required this.frameFill,
    required this.frameStroke,
    required this.frameTitle,
  });

  /// Tints are mixed over [background], the surface the diagram sits on;
  /// dark themes get stronger tints so shapes still read.
  factory MermaidPalette.of(ColorScheme colors, {required Color background}) {
    final dark = colors.brightness == Brightness.dark;
    Color tint(Color color, double light, double strong) => Color.alphaBlend(
      color.withValues(alpha: dark ? strong : light),
      background,
    );
    return MermaidPalette(
      background: background,
      nodeFill: tint(colors.primary, .09, .16),
      nodeStroke: colors.primary.withValues(alpha: .62),
      decisionFill: tint(colors.tertiary, .12, .2),
      decisionStroke: colors.tertiary.withValues(alpha: .75),
      text: colors.onSurface,
      edge: colors.onSurfaceVariant.withValues(alpha: .85),
      labelFill: tint(colors.onSurface, .07, .1),
      labelText: colors.onSurfaceVariant,
      frameFill: tint(colors.secondary, .05, .08),
      frameStroke: colors.outlineVariant,
      frameTitle: colors.onSurfaceVariant,
    );
  }

  final Color background;

  final Color nodeFill;

  final Color nodeStroke;

  /// Diamonds (decisions) stand out from the steps around them.
  final Color decisionFill;

  final Color decisionStroke;

  final Color text;

  /// Links and their arrowheads.
  final Color edge;

  /// The chip behind a link's label.
  final Color labelFill;

  final Color labelText;

  /// Subgraph frames.
  final Color frameFill;

  final Color frameStroke;

  final Color frameTitle;

  @override
  bool operator ==(Object other) =>
      other is MermaidPalette &&
      background == other.background &&
      nodeFill == other.nodeFill &&
      nodeStroke == other.nodeStroke &&
      decisionFill == other.decisionFill &&
      decisionStroke == other.decisionStroke &&
      text == other.text &&
      edge == other.edge &&
      labelFill == other.labelFill &&
      labelText == other.labelText &&
      frameFill == other.frameFill &&
      frameStroke == other.frameStroke &&
      frameTitle == other.frameTitle;

  @override
  int get hashCode => Object.hash(
    background,
    nodeFill,
    nodeStroke,
    decisionFill,
    decisionStroke,
    text,
    edge,
    labelFill,
    labelText,
    frameFill,
    frameStroke,
    frameTitle,
  );
}
