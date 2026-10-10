import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/mermaid/mermaid_flowchart.dart';
import 'package:asystant_ai/src/mermaid/mermaid_flowchart_parser.dart';
import 'package:asystant_ai/src/widgets/asystant_link_scope.dart';
import 'package:asystant_ai/src/widgets/mermaid_diagram_card.dart';
import 'package:asystant_ai/src/widgets/mermaid_source_block.dart';

/// Draws a Mermaid flowchart (`flowchart` or `graph`, any direction) from its
/// source, entirely on the device: no web view and no network service, so
/// diagrams that carry private details never leave the app.
///
/// ```dart
/// AsystantMermaidDiagram(source: 'flowchart TD\n  A[Plan] --> B{Ready?}')
/// ```
///
/// Shows a card sized to the diagram and scaled down to the width it gets,
/// never below 60 % so its text stays legible. What does not fit, in
/// width or past [AsystantTheme.diagramMaxHeight], is clipped with a fade.
/// A tap opens the diagram across the screen, with pan, pinch zoom and a
/// "View code" action for its source.
///
/// Source it cannot draw faithfully — another diagram type, a statement
/// outside the supported subset, more than 150 nodes — is shown as a code
/// block instead. [AsystantMarkdownText] uses this widget for every
/// ```` ```mermaid ```` block in a message.
///
/// Supported: nodes `A[text]`, `A(text)`, `A([text])`, `A[[text]]`,
/// `A[(text)]`, `A((text))`, `A(((text)))`, `A{text}`, `A{{text}}`,
/// `A[/text/]`, `A[\text\]`, `A[/text\]`, `A[\text/]`, `A>text]`, quoted
/// labels and `<br>`; links `-->`, `---`, `-.->`, `==>`, `~~~`, `<-->`,
/// `--o`, `--x` and their longer forms, labelled with `|text|` or
/// `-- text -->`; chains, `&` groups and `;`; nested `subgraph … end`,
/// drawn as titled frames; `%%` comments. Styling lines (`classDef`,
/// `class`, `style`, `linkStyle`, `click`) are ignored: colors follow the
/// app's theme.
class AsystantMermaidDiagram extends StatefulWidget {
  const AsystantMermaidDiagram({super.key, required this.source, this.strings});

  /// Mermaid source, without the surrounding code fence.
  final String source;

  /// Labels for the card and the full view. Defaults to those of the
  /// enclosing chat, or English outside one.
  final AsystantStrings? strings;

  @override
  State<AsystantMermaidDiagram> createState() => _AsystantMermaidDiagramState();
}

class _AsystantMermaidDiagramState extends State<AsystantMermaidDiagram> {
  MermaidFlowchart? _chart;

  @override
  void initState() {
    super.initState();
    _chart = MermaidFlowchartParser.parse(widget.source);
  }

  @override
  void didUpdateWidget(AsystantMermaidDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.source != oldWidget.source) {
      _chart = MermaidFlowchartParser.parse(widget.source);
    }
  }

  @override
  Widget build(BuildContext context) => switch (_chart) {
    final chart? => MermaidDiagramCard(
      chart: chart,
      source: widget.source,
      strings: widget.strings ?? AsystantLinkScope.stringsOf(context),
    ),
    null => MermaidSourceBlock(source: widget.source),
  };
}
