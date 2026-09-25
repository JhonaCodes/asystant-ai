import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/assistant_step.dart';
import 'package:asystant_ai/src/widgets/tool_step_row.dart';

class ToolSteps extends StatelessWidget {
  const ToolSteps({super.key, required this.steps, required this.strings});

  final List<AssistantStep> steps;

  final AsystantStrings strings;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    trailing: const AsystantGlyph(AsystantGlyphKind.chevron),
    tilePadding: EdgeInsets.zero,
    title: Text(strings.steps, style: Theme.of(context).textTheme.labelLarge),
    children: steps
        .map((step) => ToolStepRow(step: step, strings: strings))
        .toList(),
  );
}
