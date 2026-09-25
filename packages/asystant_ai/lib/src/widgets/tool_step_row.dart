import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/assistant_step.dart';

class ToolStepRow extends StatelessWidget {
  const ToolStepRow({super.key, required this.step, required this.strings});

  final AssistantStep step;

  final AsystantStrings strings;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: AsystantGlyph(switch (step.phase) {
      StepPhase.preparing => AsystantGlyphKind.search,
      StepPhase.permission => AsystantGlyphKind.shield,
      StepPhase.running => AsystantGlyphKind.refresh,
      StepPhase.completed => AsystantGlyphKind.check,
      StepPhase.declined => AsystantGlyphKind.close,
      StepPhase.canceled => AsystantGlyphKind.pause,
      StepPhase.failed => AsystantGlyphKind.warning,
    }, color: Theme.of(context).colorScheme.primary),
    title: Text(step.title),
    subtitle: Text(strings.stepPhase(step.phase)),
  );
}
