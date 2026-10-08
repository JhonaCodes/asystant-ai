import 'package:flutter/material.dart';

import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/theme/asystant_metrics.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:asystant_ai/src/widgets/asystant_icon_action.dart';
import 'package:asystant_ai/src/widgets/asystant_markdown_text.dart';

/// One message: the person's on the right in a bubble, the assistant's on
/// the left (flat across the width when the chat is compact).
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.text,
    required this.fromUser,
    required this.author,
    required this.strings,
    this.attachments = const [],
  });

  final String text;

  final bool fromUser;

  /// "You" or the assistant's name.
  final String author;

  final AsystantStrings strings;

  final List<AsystantAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    final metrics = AsystantMetrics.of(context);
    final colors = Theme.of(context).colorScheme;
    final flat = !fromUser && metrics.flatAssistantBubble;
    final showsLabel = !fromUser || metrics.showsUserLabel;
    // Measures the list's width to cap the bubble, not the device class.
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: fromUser ? .centerRight : .centerLeft,
        child: Padding(
          padding: EdgeInsets.only(bottom: metrics.messageGap),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: flat
                  ? constraints.maxWidth
                  : constraints.maxWidth * metrics.bubbleWidthFactor,
            ),
            child: Column(
              crossAxisAlignment: fromUser ? .end : .start,
              children: [
                if (showsLabel)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                    child: Text(
                      author,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                Semantics(
                  label: author,
                  child: Container(
                    padding: flat ? EdgeInsets.zero : metrics.bubblePadding,
                    decoration: switch ((fromUser, flat)) {
                      (true, _) => BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(
                          metrics.bubbleRadius,
                        ),
                      ),
                      (false, true) => null,
                      (false, false) => BoxDecoration(
                        color: colors.surfaceContainerLow,
                        border: Border.all(color: colors.outlineVariant),
                        borderRadius: BorderRadius.circular(
                          metrics.bubbleRadius,
                        ),
                      ),
                    },
                    child: Column(
                      crossAxisAlignment: .start,
                      mainAxisSize: .min,
                      children: [
                        for (final file in attachments)
                          ChatAttachmentTile(file: file, strings: strings),
                        if (text.isNotEmpty)
                          fromUser
                              ? Text(
                                  text,
                                  style: TextStyle(
                                    color: AsystantTheme.contrastOn(
                                      colors.primaryContainer,
                                    ),
                                  ),
                                )
                              : AsystantMarkdownText(text: text),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A file inside a message or waiting in the composer: icon, name and size.
class ChatAttachmentTile extends StatelessWidget {
  const ChatAttachmentTile({
    super.key,
    required this.file,
    required this.strings,
    this.onRemove,
  });

  final AsystantAttachment file;

  final AsystantStrings strings;

  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: .center,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox.square(
              dimension: 16,
              child: FittedBox(
                child: AsystantGlyph(
                  file.isImage
                      ? AsystantGlyphKind.image
                      : AsystantGlyphKind.document,
                  color: colors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                Text(
                  file.filename,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: text.labelMedium?.copyWith(color: colors.onSurface),
                ),
                Text(
                  strings.fileSize(file.size),
                  style: text.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onRemove case final remove?)
            AsystantIconAction(
              glyph: AsystantGlyphKind.close,
              tooltip: strings.removeAttachment(file.filename),
              onPressed: remove,
            )
          else
            const SizedBox(width: 4),
        ],
      ),
    );
  }
}
