import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/widgets/status_indicator.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.name,
    required this.phase,
    required this.strings,
    this.onClose,
  });

  final String name;

  final ChatPhase phase;

  final AsystantStrings strings;

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    return Padding(
      padding: EdgeInsets.all(tokens.padding),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(tokens.spacing),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(tokens.radius),
            ),
            child: AsystantGlyph(
              AsystantGlyphKind.sparkle,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          SizedBox(width: tokens.spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: tokens.spacing / 2),
                StatusIndicator(phase: phase, strings: strings),
              ],
            ),
          ),
          if (onClose case final close?)
            IconButton.filledTonal(
              tooltip: strings.close,
              onPressed: close,
              icon: const AsystantGlyph(AsystantGlyphKind.close),
            ),
        ],
      ),
    );
  }
}
