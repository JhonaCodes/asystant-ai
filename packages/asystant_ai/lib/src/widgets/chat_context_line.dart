import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/context_usage.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';

/// Context usage in the separator below the chat header.
class ChatContextLine extends StatelessWidget {
  const ChatContextLine({
    super.key,
    required this.usage,
    required this.strings,
  });

  final ContextUsage? usage;
  final AsystantStrings strings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LinearProgressIndicator(
      value: usage?.ratio ?? 0,
      minHeight: 1,
      borderRadius: BorderRadius.zero,
      stopIndicatorRadius: 0,
      trackGap: 0,
      backgroundColor: Theme.of(context).dividerColor,
      color: switch (usage?.ratio) {
        final double ratio when ratio >= ContextUsage.fullRatio => colors.error,
        final double ratio when ratio >= ContextUsage.longRatio =>
          AsystantTheme.of(context).warningColor(context),
        _ => colors.primary,
      },
      semanticsLabel: strings.contextTitle,
    );
  }
}
