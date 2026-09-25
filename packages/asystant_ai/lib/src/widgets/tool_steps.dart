import 'package:flutter/material.dart';

import '../model/assistant_step.dart';
import '../l10n/asystant_strings.dart';
import 'tool_step_row.dart';

class ToolSteps extends StatelessWidget {
  const ToolSteps({super.key, required this.steps, required this.strings});
  final List<AssistantStep> steps;
  final AsystantStrings strings;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: Text(strings.steps, style: Theme.of(context).textTheme.labelLarge),
    children: steps
        .map((step) => ToolStepRow(step: step, strings: strings))
        .toList(),
  );
}
