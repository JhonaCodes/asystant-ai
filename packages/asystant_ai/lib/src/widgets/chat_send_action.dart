import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/viewmodel/chat_view_model.dart';

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
          child: AsystantGlyph(
            state.busy ? AsystantGlyphKind.stop : AsystantGlyphKind.send,
            key: ValueKey(state.busy),
          ),
        ),
        label: Text(state.busy ? strings.stop : strings.send),
      ),
    );
  }
}
