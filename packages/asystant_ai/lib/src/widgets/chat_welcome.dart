import 'package:flutter/material.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/theme/asystant_metrics.dart';

/// The empty-conversation greeting: the assistant's glyph, a welcome title
/// and a short introduction, both from [strings].
class ChatWelcome extends StatelessWidget {
  const ChatWelcome({super.key, required this.strings});

  final AsystantStrings strings;

  @override
  Widget build(BuildContext context) {
    final metrics = AsystantMetrics.of(context);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: .center,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(metrics.identityRadius),
            ),
            child: AsystantGlyph(
              AsystantGlyphKind.sparkle,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(strings.welcome, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            strings.introduction,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
