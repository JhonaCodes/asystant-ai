import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import '../asystant_ai.dart';
import '../model/chat_state.dart';
import '../viewmodel/chat_view_model.dart';
import '../theme/asystant_theme.dart';
import '../l10n/asystant_strings.dart';
import 'chat_header.dart';
import 'chat_conversation.dart';
import 'chat_composer.dart';

/// One bounded chat section for sheets, drawers, embedded panels and full screens.
class AsystantChat extends StatelessWidget {
  const AsystantChat({
    super.key,
    required this.assistant,
    this.onClose,
    this.strings,
  });
  final AsystantAI assistant;
  final VoidCallback? onClose;
  final AsystantStrings? strings;
  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    final labels = strings ?? AsystantStrings.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: ReactiveViewModelBuilder<ChatViewModel, ChatState>(
          viewmodel: assistant.conversation.notifier,
          build: (state, vm, keep) => Column(
            children: [
              ChatHeader(
                name: assistant.name,
                phase: state.phase,
                strings: labels,
                onClose: onClose,
              ),
              const Divider(height: 1),
              Expanded(
                child: Align(
                  alignment: .topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: tokens.maxContentWidth,
                    ),
                    child: ChatConversation(
                      state: state,
                      viewModel: vm,
                      strings: labels,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: .bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: tokens.maxContentWidth),
                  child: Padding(
                    padding: EdgeInsets.all(tokens.spacing),
                    child: ChatComposer(
                      state: state,
                      viewModel: vm,
                      strings: labels,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
