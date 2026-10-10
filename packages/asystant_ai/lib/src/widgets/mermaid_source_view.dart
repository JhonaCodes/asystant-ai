import 'package:flutter/material.dart';

import 'package:asystant_ai/src/theme/asystant_theme.dart';

/// A diagram's source across a whole screen: selectable and scrollable in
/// both directions, lines kept as written.
class MermaidSourceView extends StatelessWidget {
  const MermaidSourceView({super.key, required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(AsystantTheme.of(context).padding),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          source.trimRight(),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            height: 1.5,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
