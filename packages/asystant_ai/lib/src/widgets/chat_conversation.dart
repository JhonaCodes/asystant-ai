import 'package:flutter/material.dart';

import '../model/chat_state.dart';
import '../viewmodel/chat_view_model.dart';
import '../l10n/asystant_strings.dart';
import '../theme/asystant_theme.dart';
import 'chat_timeline.dart';
import 'chat_message_bubble.dart';
import 'chat_failure_notice.dart';
import 'chat_welcome.dart';
import 'tool_steps.dart';
import 'gen_ui_card.dart';

class ChatConversation extends StatelessWidget {
  const ChatConversation({
    super.key,
    required this.state,
    required this.viewModel,
    required this.strings,
  });
  final ChatState state;
  final ChatViewModel viewModel;
  final AsystantStrings strings;
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
            final entry when entry.message != null => ChatMessageBubble(
              message: entry.message!,
            ),
            final entry when entry.card != null => GenUiCard(
              card: entry.card!,
              strings: strings,
            ),
            _ => const SizedBox.shrink(),
          },
        ),
        if (state.steps.isNotEmpty)
          ToolSteps(steps: state.steps, strings: strings),
        if (state.streaming.isNotEmpty) SelectableText(state.streaming),
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
