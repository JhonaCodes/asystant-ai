import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/assistant_step.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';

/// How a step's outcome is drawn in the activity card.
extension StepOutcomePresentation on StepOutcome {
  AsystantGlyphKind toGlyph() => switch (this) {
    .running => .pending,
    .done => .check,
    .issue => .warning,
  };

  Color toColor(BuildContext context) => switch (this) {
    .running => Theme.of(context).colorScheme.onSurfaceVariant,
    .done => AsystantTheme.of(context).successColor(context),
    .issue => Theme.of(context).colorScheme.error,
  };

  String toLabel(AsystantStrings strings) => strings.stepPhase(switch (this) {
    .running => .running,
    .done => .completed,
    .issue => .failed,
  });
}
