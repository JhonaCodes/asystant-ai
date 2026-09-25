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
      ChatPhase.idle => Icons.link_off_rounded,
      ChatPhase.initializing => Icons.sync_rounded,
      ChatPhase.ready => Icons.chat_bubble_outline_rounded,
      ChatPhase.thinking => Icons.auto_awesome_rounded,
      ChatPhase.executing => Icons.build_circle_outlined,
      ChatPhase.permission => Icons.shield_outlined,
      ChatPhase.done => Icons.check_circle_outline_rounded,
      ChatPhase.canceled => Icons.pause_circle_outline_rounded,
      ChatPhase.error => Icons.error_outline_rounded,
    };
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: .min,
        children: [
          AnimatedSwitcher(
            duration: theme.transitionDuration,
            child: Icon(
              icon,
              key: ValueKey(phase),
              size: theme.iconSize,
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
