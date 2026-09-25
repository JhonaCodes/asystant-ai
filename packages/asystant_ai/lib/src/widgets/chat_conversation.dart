import 'package:flutter/material.dart';

import 'package:asystant_ai/src/widgets/asystant_card_content.dart';
import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/chat_entry.dart';
import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/viewmodel/chat_view_model.dart';
import 'package:asystant_ai/src/widgets/chat_failure_notice.dart';
import 'package:asystant_ai/src/widgets/chat_message_bubble.dart';
import 'package:asystant_ai/src/widgets/chat_timeline.dart';
import 'package:asystant_ai/src/widgets/chat_welcome.dart';
import 'package:asystant_ai/src/widgets/gen_ui_card.dart';
import 'package:asystant_ai/src/widgets/tool_steps.dart';

class ChatConversation extends StatelessWidget {
  const ChatConversation({
    super.key,
    required this.state,
    required this.viewModel,
    required this.strings,
    this.cardContentBuilder,
  });

  final ChatState state;

  final ChatViewModel viewModel;

  final AsystantStrings strings;

  final AsystantCardContentBuilder? cardContentBuilder;

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    return ChatTimeline(
      revision: Object.hash(
        state.entries.length,
        state.streaming,
        state.pending?.call.id,
        state.steps,
      ),
      forceFollow: state.pending != null,
      padding: EdgeInsets.all(tokens.padding),
      children: [
        if (state.entries.isEmpty) ChatWelcome(strings: strings),
        ...state.entries.map(
          (entry) => switch (entry) {
            ChatEntry(message: final message?) => ChatMessageBubble(
              message: message,
            ),
            ChatEntry(card: final card?) => GenUiCard(
              card: card,
              strings: strings,
              content: cardContentBuilder?.call(context, card),
            ),
            _ => const SizedBox.shrink(),
          },
        ),
        if (state.steps.isNotEmpty)
          ToolSteps(steps: state.steps, strings: strings),
        if (state.streaming.isNotEmpty) Text(state.streaming),
        if (state.pending case final pending?)
          GenUiCard(
            card: pending.card,
            strings: strings,
            selected: pending.selected,
            onSelect: viewModel.selectOption,
            onApprove: pending.requiresSelection && pending.selected.isEmpty
                ? null
                : () => viewModel.approve(true),
            onDeny: () => viewModel.approve(false),
          ),
        if (state.failure case final failure?)
          ChatFailureNotice(failure: failure, strings: strings),
      ],
    );
  }
}
