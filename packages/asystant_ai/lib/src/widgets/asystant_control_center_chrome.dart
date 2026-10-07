// keel-debt: 3 public types in one file; split when the next major allows
//   moving declaring URIs.
import 'package:flutter/material.dart';

import 'package:asystant_ai/src/theme/asystant_theme.dart';

/// Compact AI identity for a control-center chat header.
class AsystantAiIdentity extends StatelessWidget {
  const AsystantAiIdentity({super.key});

  @override
  Widget build(BuildContext context) => Text(
    'AI',
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: AsystantTheme.contrastOn(
        Theme.of(context).colorScheme.primaryContainer,
      ),
      fontWeight: FontWeight.w900,
    ),
  );
}

/// Grid trigger for the combined navigation and conversation menu.
class AsystantGridMenuIcon extends StatelessWidget {
  const AsystantGridMenuIcon({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(
      Icons.grid_view_rounded,
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );
}

/// Short prompt and capabilities link shown over the inline composer.
class AsystantComposerHint extends StatelessWidget {
  const AsystantComposerHint({
    super.key,
    required this.prompt,
    required this.action,
    required this.onAction,
  });

  final String prompt;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          prompt,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
      TextButton(onPressed: onAction, child: Text(action)),
    ],
  );
}
