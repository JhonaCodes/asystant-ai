import 'package:flutter/material.dart';

import '../model/chat_state.dart';
import '../viewmodel/chat_view_model.dart';
import '../l10n/asystant_strings.dart';
import '../theme/asystant_theme.dart';

class ChatSendAction extends StatelessWidget {
  const ChatSendAction({
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
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: tokens.actionHeight),
      child: FilledButton.icon(
        onPressed: switch ((state.busy, viewModel.canSend)) {
          (true, _) => viewModel.cancel,
          (false, true) => () => viewModel.send(),
          _ => null,
        },
        icon: AnimatedSwitcher(
          duration: kThemeAnimationDuration,
          child: Icon(
            state.busy ? Icons.stop_rounded : Icons.arrow_upward_rounded,
            key: ValueKey(state.busy),
            size: tokens.iconSize,
          ),
        ),
        label: Text(state.busy ? strings.stop : strings.send),
      ),
    );
  }
}
