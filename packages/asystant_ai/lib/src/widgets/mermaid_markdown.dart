import 'package:flutter/widgets.dart';

import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:asystant_ai/src/mermaid/mermaid_flowchart_parser.dart';
import 'package:asystant_ai/src/widgets/asystant_mermaid_diagram.dart';

/// Reads a ```` ```mermaid ```` fence whose source is a flowchart this
/// library draws into a [tag] element. Any other fence, and a Mermaid one it
/// cannot draw, stays the ordinary code block.
class MermaidFenceSyntax extends md.FencedCodeBlockSyntax {
  const MermaidFenceSyntax();

  /// The element [MermaidMarkdownBuilder] turns into a diagram.
  static const String tag = 'mermaid';

  @override
  bool canParse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content);
    final info =
        match?.namedGroup('backtickInfo') ?? match?.namedGroup('tildeInfo');
    return info?.trim().split(RegExp(r'\s')).first.toLowerCase() == 'mermaid';
  }

  @override
  md.Node parse(md.BlockParser parser) {
    // The same `pre > code` node the standard fence produces, so source it
    // cannot draw renders exactly as before.
    final block = super.parse(parser);
    final source = block.textContent;
    return MermaidFlowchartParser.parse(source) == null
        ? block
        : md.Element.text(tag, source);
  }
}

/// Builds an [AsystantMermaidDiagram] for each [MermaidFenceSyntax.tag].
///
/// Registered as an inline builder on purpose: `flutter_markdown_plus`
/// appends every block builder's tag to a global list on each parse.
class MermaidMarkdownBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) => AsystantMermaidDiagram(source: element.textContent);
}
