import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/assistant_step.dart';
import 'package:asystant_ai/src/model/chat_entry.dart';
import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:asystant_ai/src/widgets/step_outcome_presentation.dart';

/// How the folded line of a finished turn sums up what the assistant did.
extension FinishedActivityPresentation on ChatEntry {
  StepOutcome get _outcome =>
      activityHasIssues ? StepOutcome.issue : StepOutcome.done;

  AsystantGlyphKind toActivityGlyph() => _outcome.toGlyph();

  Color toActivityTone(BuildContext context) => _outcome.toColor(context);

  String toActivitySteps(AsystantStrings strings) =>
      strings.activitySteps(activity.length);

  String toActivityEnding(AsystantStrings strings) => activityHasIssues
      ? strings.activityFinishedWithIssues
      : strings.activityFinished;
}

/// How the live activity card names what the assistant is doing.
extension TurnActivityPresentation on TurnActivity {
  AsystantGlyphKind toGlyph() => switch (this) {
    .thinking => .thinking,
    .writing => .writing,
    .usingTool => .tool,
  };

  String toTitle(AsystantStrings strings, String name) => switch (this) {
    .thinking => strings.thinkingAs(name),
    .writing => strings.writingAs(name),
    .usingTool => strings.usingToolAs(name),
  };

  /// The last row of the live card; a running tool has none.
  String? toClosingStep(AsystantStrings strings) => switch (this) {
    .thinking => strings.analyzing,
    .writing => strings.drafting,
    .usingTool => null,
  };
}
