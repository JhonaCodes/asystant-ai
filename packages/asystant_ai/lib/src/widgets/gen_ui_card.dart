import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:flutter/material.dart';

import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/asystant_card_action.dart';
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
    this.onOptionPressed,
    this.onApprove,
    this.onDeny,
    this.approveLabel,
    this.denyLabel,
    this.content,
    this.framed = true,
    this.actions = const [],
  });

  final AssistantCard card;

  /// The host's buttons, under everything else (see `AsystantHostCard`).
  final List<AsystantCardAction> actions;

  /// Optional host-rendered content; use only with trusted local tool results.
  final Widget? content;

  /// Draws its own border; off when another card already frames it.
  final bool framed;

  final AsystantStrings strings;

  final List<String> selected;

  final ValueChanged<String>? onSelect;

  /// A completed card's suggested action. Pending selection uses [onSelect].
  final ValueChanged<String>? onOptionPressed;

  final VoidCallback? onApprove;

  final VoidCallback? onDeny;

  final String? approveLabel;

  final String? denyLabel;

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
      onOptionPressed: onOptionPressed,
      onApprove: onApprove,
      onDeny: onDeny,
      approveLabel: approveLabel,
      denyLabel: denyLabel,
      actions: actions,
    );
    // A card waiting for the person stands out, like a permission request.
    final awaitsDecision =
        onApprove != null || actions.any((action) => action.onPressed != null);
    if (!framed) {
      return contents;
    }
    return Container(
      margin: EdgeInsets.only(bottom: tokens.spacing),
      padding: EdgeInsets.all(tokens.padding),
      decoration: BoxDecoration(
        color: awaitsDecision
            ? colors.surfaceContainerHigh
            : colors.surfaceContainerLow,
        border: Border.all(
          color: awaitsDecision
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
    this.onOptionPressed,
    this.onApprove,
    this.onDeny,
    this.approveLabel,
    this.denyLabel,
    this.content,
    this.actions = const [],
  });

  final AssistantCard card;

  /// Optional host-rendered content; use only with trusted local tool results.
  final Widget? content;

  final List<AsystantCardAction> actions;

  final AsystantStrings strings;

  final List<String> selected;

  final ValueChanged<String>? onSelect;

  final ValueChanged<String>? onOptionPressed;

  final VoidCallback? onApprove;

  final VoidCallback? onDeny;

  final String? approveLabel;

  final String? denyLabel;

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
        if (card.options.isNotEmpty &&
            (onSelect != null || onOptionPressed != null)) ...[
          SizedBox(height: tokens.spacing),
          _CardOptions(
            options: card.options,
            selected: selected,
            onSelect: onSelect,
            onOptionPressed: onOptionPressed,
            stacked:
                card.kind == AssistantCardKind.selection &&
                onOptionPressed != null,
          ),
        ],
        if (onDeny case final deny?) ...[
          SizedBox(height: tokens.spacing),
          _CardConfirmation(
            strings: strings,
            onDeny: deny,
            onApprove: onApprove,
            approveLabel: approveLabel,
            denyLabel: denyLabel,
          ),
        ],
        if (actions.isNotEmpty) ...[
          SizedBox(height: tokens.spacing),
          _CardActions(actions: actions),
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
    this.onOptionPressed,
    this.stacked = false,
  });

  final List<String> options;

  final List<String> selected;

  final ValueChanged<String>? onSelect;

  final ValueChanged<String>? onOptionPressed;

  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    if (stacked) {
      return Column(
        crossAxisAlignment: .stretch,
        children: [
          for (final (index, option) in options.indexed) ...[
            OutlinedButton(
              onPressed: onOptionPressed == null
                  ? null
                  : () => onOptionPressed!(option),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(option, textAlign: TextAlign.start),
            ),
            if (index < options.length - 1)
              SizedBox(height: tokens.spacing / 2),
          ],
        ],
      );
    }
    return Wrap(
      spacing: tokens.spacing / 2,
      runSpacing: tokens.spacing / 2,
      children: [
        for (final option in options)
          if (onSelect case final select?)
            FilterChip(
              label: Text(option),
              selected: selected.contains(option),
              onSelected: (_) => select(option),
            )
          else
            OutlinedButton(
              onPressed: onOptionPressed == null
                  ? null
                  : () => onOptionPressed!(option),
              child: Text(option),
            ),
      ],
    );
  }
}

class _CardConfirmation extends StatelessWidget {
  const _CardConfirmation({
    required this.strings,
    required this.onDeny,
    this.onApprove,
    this.approveLabel,
    this.denyLabel,
  });

  final AsystantStrings strings;

  final VoidCallback onDeny;

  final VoidCallback? onApprove;

  final String? approveLabel;

  final String? denyLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    return Wrap(
      spacing: tokens.spacing - 4,
      runSpacing: tokens.spacing - 4,
      children: [
        OutlinedButton(
          onPressed: onDeny,
          child: Text(denyLabel ?? strings.deny),
        ),
        FilledButton(
          onPressed: onApprove,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: AsystantTheme.contrastOn(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          child: Text(approveLabel ?? strings.allow),
        ),
      ],
    );
  }
}

/// The host's buttons of a card: the primary one filled, the rest outlined.
class _CardActions extends StatelessWidget {
  const _CardActions({required this.actions});

  final List<AsystantCardAction> actions;

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    return Wrap(
      spacing: tokens.spacing - 4,
      runSpacing: tokens.spacing - 4,
      children: [
        for (final action in actions)
          switch (action.isPrimary) {
            true => FilledButton(
              onPressed: action.onPressed,
              child: Text(action.label),
            ),
            false => OutlinedButton(
              onPressed: action.onPressed,
              child: Text(action.label),
            ),
          },
      ],
    );
  }
}
