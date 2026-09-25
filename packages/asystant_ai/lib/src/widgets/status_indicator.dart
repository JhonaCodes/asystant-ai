import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';

class StatusIndicator extends StatelessWidget {
  const StatusIndicator({
    super.key,
    required this.phase,
    required this.strings,
  });

  final ChatPhase phase;

  final AsystantStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = AsystantTheme.of(context);
    final icon = switch (phase) {
      ChatPhase.idle => AsystantGlyphKind.chat,
      ChatPhase.initializing => AsystantGlyphKind.refresh,
      ChatPhase.ready => AsystantGlyphKind.chat,
      ChatPhase.thinking => AsystantGlyphKind.sparkle,
      ChatPhase.executing => AsystantGlyphKind.refresh,
      ChatPhase.permission => AsystantGlyphKind.shield,
      ChatPhase.done => AsystantGlyphKind.check,
      ChatPhase.canceled => AsystantGlyphKind.pause,
      ChatPhase.error => AsystantGlyphKind.warning,
    };
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: .min,
        children: [
          AnimatedSwitcher(
            duration: theme.transitionDuration,
            child: AsystantGlyph(
              icon,
              key: ValueKey(phase),
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: theme.spacing / 2),
          Flexible(
            child: Text(
              strings.phase(phase),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          if (phase == ChatPhase.thinking ||
              phase == ChatPhase.initializing) ...[
            SizedBox(width: theme.spacing),
            SizedBox.square(
              dimension: theme.iconSize / 2,
              child: CircularProgressIndicator(
                strokeWidth: theme.progressStrokeWidth,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
