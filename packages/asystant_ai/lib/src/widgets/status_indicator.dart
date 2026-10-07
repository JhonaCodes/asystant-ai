import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:flutter/material.dart';
import 'package:asystant_ai/src/widgets/chat_activity_pulse.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/widgets/chat_phase_presentation.dart';

/// A glyph and short label for the current [ChatPhase], animated on change.
/// Announced as a live region so assistive technology reads phase changes.
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
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: .min,
        children: [
          AnimatedSwitcher(
            duration: theme.transitionDuration,
            child: ChatActivityPulse(
              key: ValueKey(phase),
              active: phase.isPulsing,
              child: AsystantGlyph(
                phase.toGlyph(),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          SizedBox(width: theme.spacing / 2),
          Flexible(
            child: Text(
              strings.phase(phase),
              maxLines: 1,
              overflow: .ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}
