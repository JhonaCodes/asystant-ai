import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/widgets/asystant_image_placeholder.dart';
import 'package:asystant_ai/src/widgets/asystant_link_scope.dart';

/// Renders completed text with links; selection belongs to the chat's area.
///
/// MarkdownBody caches parsing until its text or theme changes. Streaming text
/// deliberately uses ordinary Text until a complete message is available.
class AsystantMarkdownText extends StatefulWidget {
  const AsystantMarkdownText({super.key, required this.text});

  final String text;

  @override
  State<AsystantMarkdownText> createState() => _AsystantMarkdownTextState();
}

class _AsystantMarkdownTextState extends State<AsystantMarkdownText> {
  bool _linkFailed = false;

  void _onTapLink(String label, String? destination, String title) {
    unawaited(_openLink(destination));
  }

  Future<void> _openLink(String? destination) async {
    final opened = await AsystantLinkScope.openerOf(context).open(destination);
    if (mounted) {
      setState(() => _linkFailed = !opened);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    mainAxisSize: .min,
    children: [
      MarkdownBody(
        data: widget.text,
        fitContent: true,
        onTapLink: _onTapLink,
        imageBuilder: AsystantImagePlaceholder.new,
      ),
      if (_linkFailed) ...[
        SizedBox(height: AsystantTheme.of(context).spacing),
        Semantics(
          liveRegion: true,
          child: Text(
            AsystantLinkScope.stringsOf(context).linkFailure,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    ],
  );
}
