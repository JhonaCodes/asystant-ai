import 'package:asystant_core/asystant_core.dart';
import 'package:flutter/material.dart';

import '../theme/asystant_theme.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message});
  final AssistantMessage message;
  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    return Align(
      alignment: message.role == MessageRole.user
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: tokens.padding),
        padding: EdgeInsets.all(tokens.spacing),
        decoration: BoxDecoration(
          color: message.role == MessageRole.user
              ? Theme.of(context).colorScheme.secondaryContainer
              : null,
          borderRadius: BorderRadius.circular(tokens.radius),
        ),
        child: SelectableText(message.content),
      ),
    );
  }
}
