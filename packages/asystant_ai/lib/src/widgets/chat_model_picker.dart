import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/asystant_model_option.dart';
import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/viewmodel/chat_view_model.dart';
import 'package:asystant_ai/src/widgets/asystant_disabled_colors.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';

/// The chosen model next to the send button: its icon, its name and a ▾.
/// Tapping it lists every level the host configured.
///
/// Draws nothing when there is only one model or the host fixes it.
class ChatModelPicker extends StatelessWidget {
  const ChatModelPicker({
    super.key,
    required this.state,
    required this.viewModel,
    required this.strings,
    this.compact = false,
  });

  final ChatState state;

  final ChatViewModel viewModel;

  final AsystantStrings strings;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!state.offersModelChoice) {
      return const SizedBox.shrink();
    }
    final current = state.optionOf(state.model);
    return PopupMenuButton<String>(
      tooltip: strings.model,
      // The chip stays compact; its touch area reaches 48 like Send.
      style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.padded),
      enabled: !state.busy,
      initialValue: state.model,
      onSelected: viewModel.selectModel,
      itemBuilder: (_) => [
        for (final option in state.modelOptions)
          PopupMenuItem(
            value: option.id,
            child: _ModelOptionRow(
              option: option,
              selected: option.id == state.model,
            ),
          ),
      ],
      child: compact
          ? Icon(Icons.tune_rounded, color: colorFor(context, !state.busy))
          : _ModelChip(option: current, enabled: !state.busy),
    );
  }

  Color colorFor(BuildContext context, bool enabled) => enabled
      ? Theme.of(context).colorScheme.onSurfaceVariant
      : Theme.of(context).colorScheme.disabledContent;
}

class _ModelChip extends StatelessWidget {
  const _ModelChip({required this.option, required this.enabled});

  final AsystantModelOption option;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = enabled ? colors.onSurfaceVariant : colors.disabledContent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: .min,
        children: [
          if (option.icon case final icon?) ...[
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            option.label,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: color),
          ),
          const SizedBox(width: 2),
          SizedBox.square(
            dimension: 16,
            child: FittedBox(
              child: AsystantGlyph(AsystantGlyphKind.chevron, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelOptionRow extends StatelessWidget {
  const _ModelOptionRow({required this.option, required this.selected});

  final AsystantModelOption option;

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: switch (option.icon) {
            final icon? => Icon(icon, size: 20, color: colors.primary),
            null => const SizedBox.shrink(),
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              Text(option.label, style: text.bodyLarge),
              if (option.description.isNotEmpty)
                Text(
                  option.description,
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (selected)
          SizedBox.square(
            dimension: 18,
            child: FittedBox(
              child: AsystantGlyph(
                AsystantGlyphKind.check,
                color: colors.primary,
              ),
            ),
          ),
      ],
    );
  }
}
