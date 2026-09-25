import 'package:flutter/material.dart';
import 'package:asystant_core/asystant_core.dart';

import '../theme/asystant_theme.dart';
import '../l10n/asystant_strings.dart';

/// Renders a structured card and forwards explicit user choices to the host.
class GenUiCard extends StatelessWidget {
  const GenUiCard({
    super.key,
    required this.card,
    required this.strings,
    this.selected = const [],
    this.onSelect,
    this.onApprove,
    this.onDeny,
  });
  final AssistantCard card;
  final AsystantStrings strings;
  final List<String> selected;
  final ValueChanged<String>? onSelect;
  final VoidCallback? onApprove, onDeny;
  @override
  Widget build(BuildContext context) {
    final theme = AsystantTheme.of(context);
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: theme.spacing),
      padding: EdgeInsets.all(theme.padding),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(
          color: onApprove != null
              ? colors.primary.withValues(alpha: .4)
              : colors.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(theme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                switch (card.kind) {
                  AssistantCardKind.summary => Icons.subject_rounded,
                  AssistantCardKind.entity => Icons.article_outlined,
                  AssistantCardKind.selection => Icons.checklist_rounded,
                  AssistantCardKind.permission => Icons.shield_outlined,
                  AssistantCardKind.result => Icons.task_alt_rounded,
                },
                size: theme.iconSize,
                color: colors.primary,
              ),
              SizedBox(width: theme.spacing),
              Expanded(
                child: Text(
                  card.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          if (card.body.isNotEmpty) ...[
            SizedBox(height: theme.spacing),
            Text(card.body),
          ],
          if (card.options.isNotEmpty) ...[
            SizedBox(height: theme.spacing),
            Wrap(
              spacing: theme.spacing / 2,
              runSpacing: theme.spacing / 2,
              children: [
                for (final option in card.options)
                  FilterChip(
                    label: Text(option),
                    selected: selected.contains(option),
                    onSelected: onSelect == null
                        ? null
                        : (_) => onSelect!(option),
                  ),
              ],
            ),
          ],
          if (onDeny != null) ...[
            SizedBox(height: theme.spacing),
            Text(
              strings.confirmation,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: theme.spacing),
            Wrap(
              spacing: theme.spacing,
              children: [
                FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(strings.allow),
                ),
                TextButton(onPressed: onDeny, child: Text(strings.deny)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
