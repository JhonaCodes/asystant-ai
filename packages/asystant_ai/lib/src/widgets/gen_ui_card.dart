import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:flutter/material.dart';

import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/widgets/asystant_markdown_text.dart';
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
    this.content,
    this.framed = true,
  });

  final AssistantCard card;

  /// Optional host-rendered content; use only with trusted local tool results.
  final Widget? content;

  /// Draws its own border; off when another card already frames it.
  final bool framed;

  final AsystantStrings strings;

  final List<String> selected;

  final ValueChanged<String>? onSelect;

  final VoidCallback? onApprove;

  final VoidCallback? onDeny;

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    final colors = Theme.of(context).colorScheme;
    final contents = _CardContents(
      content: content,
      card: card,
      strings: strings,
      selected: selected,
      onSelect: onSelect,
      onApprove: onApprove,
      onDeny: onDeny,
    );
    if (!framed) {
      return contents;
    }
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
      child: contents,
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
    this.content,
  });

  final AssistantCard card;

  /// Optional host-rendered content; use only with trusted local tool results.
  final Widget? content;

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
          AsystantMarkdownText(text: card.body),
        ],
        if (card.chart case final chart?) ...[
          SizedBox(height: tokens.spacing),
          GenUiChart(chart: chart),
        ],
        if (content case final content?) ...[
          SizedBox(height: tokens.spacing),
          content,
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
        AsystantGlyph(switch (card.kind) {
          AssistantCardKind.summary => AsystantGlyphKind.document,
          AssistantCardKind.entity => AsystantGlyphKind.document,
          AssistantCardKind.selection => AsystantGlyphKind.check,
          AssistantCardKind.permission => AsystantGlyphKind.shield,
          AssistantCardKind.result => AsystantGlyphKind.check,
        }, color: theme.colorScheme.primary),
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
    return Wrap(
      spacing: tokens.spacing - 4,
      runSpacing: tokens.spacing - 4,
      children: [
        OutlinedButton(onPressed: onDeny, child: Text(strings.deny)),
        FilledButton(onPressed: onApprove, child: Text(strings.allow)),
      ],
    );
  }
}
