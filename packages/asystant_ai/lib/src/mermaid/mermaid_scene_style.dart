import 'package:flutter/material.dart';

import 'package:asystant_ai/src/mermaid/mermaid_palette.dart';

/// Text and colors one diagram is built with, read from the surrounding
/// theme so a diagram matches the chat it appears in.
@immutable
class MermaidSceneStyle {
  const MermaidSceneStyle({
    required this.palette,
    required this.nodeText,
    required this.labelText,
    required this.titleText,
    this.textScaler = TextScaler.noScaling,
    this.textDirection = TextDirection.ltr,
  });

  /// [background] is the surface the diagram is painted on.
  factory MermaidSceneStyle.of(
    BuildContext context, {
    required Color background,
  }) {
    final theme = Theme.of(context);
    final palette = MermaidPalette.of(
      theme.colorScheme,
      background: background,
    );
    final body = theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    return MermaidSceneStyle(
      palette: palette,
      nodeText: body.copyWith(color: palette.text, height: 1.3),
      labelText: (theme.textTheme.bodySmall ?? body).copyWith(
        color: palette.labelText,
        height: 1.25,
      ),
      titleText: (theme.textTheme.labelMedium ?? body).copyWith(
        color: palette.frameTitle,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
    );
  }

  final MermaidPalette palette;

  /// Inside nodes.
  final TextStyle nodeText;

  /// On links.
  final TextStyle labelText;

  /// Subgraph titles.
  final TextStyle titleText;

  final TextScaler textScaler;

  final TextDirection textDirection;

  /// Node text size relative to 14 px, after the host's text scaling, so
  /// padding and gaps grow with the text.
  double get unit => textScaler.scale(nodeText.fontSize ?? 14) / 14;

  @override
  bool operator ==(Object other) =>
      other is MermaidSceneStyle &&
      palette == other.palette &&
      nodeText == other.nodeText &&
      labelText == other.labelText &&
      titleText == other.titleText &&
      textScaler == other.textScaler &&
      textDirection == other.textDirection;

  @override
  int get hashCode => Object.hash(
    palette,
    nodeText,
    labelText,
    titleText,
    textScaler,
    textDirection,
  );
}
