import 'package:flutter/material.dart';

import '../model/assistant_step.dart';
import '../l10n/asystant_strings.dart';
import '../theme/asystant_theme.dart';

class ToolStepRow extends StatelessWidget {
  const ToolStepRow({super.key, required this.step, required this.strings});
  final AssistantStep step;
  final AsystantStrings strings;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      switch (step.phase) {
        StepPhase.preparing => Icons.search_rounded,
        StepPhase.permission => Icons.shield_outlined,
        StepPhase.running => Icons.build_circle_outlined,
        StepPhase.completed => Icons.check_circle_outline_rounded,
        StepPhase.declined => Icons.block_rounded,
        StepPhase.canceled => Icons.pause_circle_outline_rounded,
        StepPhase.failed => Icons.error_outline_rounded,
      },
      color: Theme.of(context).colorScheme.primary,
      size: AsystantTheme.of(context).iconSize,
    ),
    title: Text(step.title),
    subtitle: Text(strings.stepPhase(step.phase)),
  );
}
