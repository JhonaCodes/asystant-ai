import 'package:flutter/material.dart';

import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/widgets/gen_ui_chart.dart';

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

  final VoidCallback? onApprove;

  final VoidCallback? onDeny;

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: tokens.spacing),
      padding: EdgeInsets.all(tokens.padding),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(
          color: onApprove != null
              ? colors.primary.withValues(alpha: tokens.permissionBorderOpacity)
              : colors.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(tokens.radius),
      ),
      child: _CardContents(
        card: card,
        strings: strings,
        selected: selected,
        onSelect: onSelect,
        onApprove: onApprove,
        onDeny: onDeny,
      ),
    );
  }
}

class _CardContents extends StatelessWidget {
  const _CardContents({
    required this.card,
    required this.strings,
    required this.selected,
    this.onSelect,
    this.onApprove,
    this.onDeny,
  });

  final AssistantCard card;

  final AsystantStrings strings;

  final List<String> selected;

  final ValueChanged<String>? onSelect;

  final VoidCallback? onApprove;

  final VoidCallback? onDeny;

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    return Column(
      crossAxisAlignment: .start,
      children: [
        _CardHeader(card: card),
        if (card.body.isNotEmpty) ...[
          SizedBox(height: tokens.spacing),
          Text(card.body),
        ],
        if (card.chart case final chart?) ...[
          SizedBox(height: tokens.spacing),
          GenUiChart(chart: chart),
        ],
        if (card.options.isNotEmpty) ...[
          SizedBox(height: tokens.spacing),
          _CardOptions(
            options: card.options,
            selected: selected,
            onSelect: onSelect,
          ),
        ],
        if (onDeny case final deny?) ...[
          SizedBox(height: tokens.spacing),
          _CardConfirmation(
            strings: strings,
            onDeny: deny,
            onApprove: onApprove,
          ),
        ],
      ],
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.card});

  final AssistantCard card;

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          switch (card.kind) {
            AssistantCardKind.summary => Icons.subject_rounded,
            AssistantCardKind.entity => Icons.article_outlined,
            AssistantCardKind.selection => Icons.checklist_rounded,
            AssistantCardKind.permission => Icons.shield_outlined,
            AssistantCardKind.result => Icons.task_alt_rounded,
          },
          size: tokens.iconSize,
          color: theme.colorScheme.primary,
        ),
        SizedBox(width: tokens.spacing),
        Expanded(child: Text(card.title, style: theme.textTheme.titleSmall)),
      ],
    );
  }
}

class _CardOptions extends StatelessWidget {
  const _CardOptions({
    required this.options,
    required this.selected,
    this.onSelect,
  });

  final List<String> options;

  final List<String> selected;

  final ValueChanged<String>? onSelect;

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    return Wrap(
      spacing: tokens.spacing / 2,
      runSpacing: tokens.spacing / 2,
      children: options
          .map(
            (option) => FilterChip(
              label: Text(option),
              selected: selected.contains(option),
              onSelected: switch (onSelect) {
                final select? => (_) => select(option),
                null => null,
              },
            ),
          )
          .toList(),
    );
  }
}

class _CardConfirmation extends StatelessWidget {
  const _CardConfirmation({
    required this.strings,
    required this.onDeny,
    this.onApprove,
  });

  final AsystantStrings strings;

  final VoidCallback onDeny;

  final VoidCallback? onApprove;

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          strings.confirmation,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SizedBox(height: tokens.spacing),
        Wrap(
          spacing: tokens.spacing,
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
    );
  }
}
