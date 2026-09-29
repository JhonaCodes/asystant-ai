import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/context_usage.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';

/// How full the conversation is, as a percentage; tap for the detail.
///
/// Hidden while the model's context window is unknown.
class ChatContextMeter extends StatelessWidget {
  const ChatContextMeter({
    super.key,
    required this.usage,
    required this.strings,
  });

  final ContextUsage usage;

  final AsystantStrings strings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tone = usage.isLong
        ? AsystantTheme.of(context).warningColor(context)
        : colors.onSurfaceVariant;
    return switch ((usage.percent, usage.ratio, usage.limit)) {
      (final int percent, final double ratio, final int limit) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => _ContextDetail(
            percent: percent,
            used: usage.used,
            limit: limit,
            strings: strings,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: .min,
            children: [
              SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 2,
                  backgroundColor: colors.surfaceContainerHighest,
                  color: usage.isLong ? tone : colors.primary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                strings.contextPercent(percent),
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: tone),
              ),
            ],
          ),
        ),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _ContextDetail extends StatelessWidget {
  const _ContextDetail({
    required this.percent,
    required this.used,
    required this.limit,
    required this.strings,
  });

  final int percent;

  final int used;

  final int limit;

  final AsystantStrings strings;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(strings.contextTitle),
    content: Text(strings.contextDetail(percent, used, limit)),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(strings.understood),
      ),
    ],
  );
}
