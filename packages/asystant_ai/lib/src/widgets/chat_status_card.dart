import 'package:flutter/material.dart';

import 'package:asystant_ai/src/theme/asystant_metrics.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';

/// A bordered notice inside the conversation: an icon and its content.
class ChatStatusCard extends StatelessWidget {
  const ChatStatusCard({
    super.key,
    required this.icon,
    required this.child,
    this.color,
  });

  final AsystantGlyphKind icon;

  final Widget child;

  /// Border and icon color; the outline color when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final metrics = AsystantMetrics.of(context);
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: metrics.messageGap),
      padding: EdgeInsets.all(metrics.cardPadding),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: color ?? colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          AsystantGlyph(icon, color: color ?? colors.primary),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}
