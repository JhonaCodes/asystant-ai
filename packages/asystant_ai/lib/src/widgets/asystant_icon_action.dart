import 'package:flutter/material.dart';

import 'package:asystant_ai/src/widgets/asystant_disabled_colors.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';

/// An icon button with a tooltip, drawn with an [AsystantGlyph].
///
/// The flags keep each call site's original look: they are not variants.
class AsystantIconAction extends StatelessWidget {
  const AsystantIconAction({
    super.key,
    required this.glyph,
    required this.tooltip,
    required this.onPressed,
    this.compact = true,
    this.fixedTarget = false,
    this.dimsWhenDisabled = false,
  });

  final AsystantGlyphKind glyph;

  final String tooltip;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// Compact visual density; off keeps the theme's density.
  final bool compact;

  /// Pins a 40 dp box with 8 dp padding; off keeps the IconButton defaults.
  final bool fixedTarget;

  /// Draws the glyph in the disabled color when [onPressed] is null.
  final bool dimsWhenDisabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      visualDensity: compact ? VisualDensity.compact : null,
      constraints: fixedTarget
          ? const BoxConstraints(minWidth: 40, minHeight: 40)
          : null,
      padding: fixedTarget ? const EdgeInsets.all(8) : null,
      onPressed: onPressed,
      icon: AsystantGlyph(
        glyph,
        color: dimsWhenDisabled && onPressed == null
            ? colors.disabledContent
            : colors.onSurfaceVariant,
      ),
    );
  }
}
