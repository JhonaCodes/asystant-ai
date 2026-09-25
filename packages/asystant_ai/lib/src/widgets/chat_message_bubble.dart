import 'package:flutter/material.dart';

import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/widgets/asystant_markdown_text.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    return Align(
      alignment: message.role == MessageRole.user ? .centerRight : .centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: tokens.padding),
        padding: EdgeInsets.all(tokens.spacing),
        decoration: BoxDecoration(
          color: message.role == MessageRole.user
              ? Theme.of(context).colorScheme.primaryContainer
                    .withValues(alpha: .55)
              : null,
          borderRadius: BorderRadius.circular(tokens.radius),
        ),
        child: AsystantMarkdownText(text: message.content),
      ),
    );
  }
}
