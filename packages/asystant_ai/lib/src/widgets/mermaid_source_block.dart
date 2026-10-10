import 'package:flutter/material.dart';

import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Diagram source shown the way a Markdown code block is: what a message
/// shows when its diagram cannot be drawn.
class MermaidSourceBlock extends StatelessWidget {
  const MermaidSourceBlock({super.key, required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final sheet = MarkdownStyleSheet.fromTheme(Theme.of(context));
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: sheet.codeblockDecoration,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: sheet.codeblockPadding,
        child: Text(source.trimRight(), style: sheet.code),
      ),
    );
  }
}
