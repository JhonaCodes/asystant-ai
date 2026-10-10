import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/service/asystant_link_opener.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/widgets/asystant_image_placeholder.dart';
import 'package:asystant_ai/src/widgets/asystant_link_scope.dart';
import 'package:asystant_ai/src/widgets/mermaid_markdown.dart';

/// Renders Markdown an assistant wrote — paragraphs, lists, tables, code
/// blocks, links — the way the chat shows a completed message, including
/// ```` ```mermaid ```` flowcharts drawn as diagrams ([AsystantMermaidDiagram]).
///
/// Use it to show agent text outside [AsystantChat] too: task history,
/// decisions, activity logs.
///
/// ```dart
/// AsystantMarkdownText(
///   text: entry.summary,
///   selectable: true,
///   onOpenLink: (uri) async => router.openIfInternal(uri),
///   strings: AsystantStrings.spanishLabels,
/// )
/// ```
///
/// Links open only on an explicit tap, after the same validation the chat
/// applies: HTTP(S) only, no embedded credentials. Image markup shows its
/// alternative text; nothing is fetched. Parsing is cached until [text] or
/// the theme changes; for text that is still streaming, show plain text and
/// switch to this widget once it is complete.
class AsystantMarkdownText extends StatefulWidget {
  const AsystantMarkdownText({
    super.key,
    required this.text,
    this.style,
    this.selectable = false,
    this.onOpenLink,
    this.strings,
  });

  /// The Markdown source.
  final String text;

  /// Merged over the paragraph style: the theme's `bodyMedium` with a 1.5
  /// line height.
  final TextStyle? style;

  /// Wraps the text in its own [SelectionArea]. Leave it off inside an area
  /// that is already selectable, such as the chat's conversation.
  final bool selectable;

  /// Handles a tapped link; return false to show the "could not open"
  /// notice. Defaults to the enclosing chat's handler or, outside a chat,
  /// to opening the external browser.
  final AsystantLinkCallback? onOpenLink;

  /// Labels for link feedback and diagrams. Defaults to the enclosing
  /// chat's, or English outside one.
  final AsystantStrings? strings;

  @override
  State<AsystantMarkdownText> createState() => _AsystantMarkdownTextState();
}

class _AsystantMarkdownTextState extends State<AsystantMarkdownText> {
  bool _linkFailed = false;

  /// Created once: a builder per build would be new identity for nothing.
  final Map<String, MarkdownElementBuilder> _builders = {
    MermaidFenceSyntax.tag: MermaidMarkdownBuilder(),
  };

  AsystantLinkOpener get _opener => switch (widget.onOpenLink) {
    final onOpenLink? => AsystantLinkOpener(onOpenLink: onOpenLink),
    null => AsystantLinkScope.openerOf(context),
  };

  void _onTapLink(String label, String? destination, String title) {
    unawaited(_openLink(destination));
  }

  Future<void> _openLink(String? destination) async {
    final opened = await _opener.open(destination);
    if (mounted) {
      setState(() => _linkFailed = !opened);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = widget.strings ?? AsystantLinkScope.stringsOf(context);
    final paragraph = theme.textTheme.bodyMedium?.copyWith(height: 1.5);
    final content = AsystantLinkScope(
      opener: _opener,
      strings: strings,
      child: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        children: [
          MarkdownBody(
            data: widget.text,
            styleSheet: MarkdownStyleSheet.fromTheme(theme)
                .copyWith(p: paragraph?.merge(widget.style) ?? widget.style),
            fitContent: true,
            onTapLink: _onTapLink,
            imageBuilder: AsystantImagePlaceholder.new,
            blockSyntaxes: const [MermaidFenceSyntax()],
            builders: _builders,
          ),
          if (_linkFailed) ...[
            SizedBox(height: AsystantTheme.of(context).spacing),
            Semantics(
              liveRegion: true,
              child: Text(
                strings.linkFailure,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
    return widget.selectable ? SelectionArea(child: content) : content;
  }
}
