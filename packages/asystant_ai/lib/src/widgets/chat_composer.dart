import 'package:flutter/material.dart';

import '../model/chat_state.dart';
import '../viewmodel/chat_view_model.dart';
import '../l10n/asystant_strings.dart';
import '../theme/asystant_theme.dart';
import 'chat_model_picker.dart';
import 'chat_send_action.dart';

/// Controllers are widget lifecycle resources; conversation state lives in the VM.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.state,
    required this.viewModel,
    required this.strings,
  });
  final ChatState state;
  final ChatViewModel viewModel;
  final AsystantStrings strings;
  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final TextEditingController _text = TextEditingController();
  @override
  void initState() {
    super.initState();
    _text.text = widget.state.draft;
  }

  @override
  void didUpdateWidget(covariant ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_text.text != widget.state.draft)
      _text.value = TextEditingValue(
        text: widget.state.draft,
        selection: TextSelection.collapsed(offset: widget.state.draft.length),
      );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(tokens.spacing),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _text,
            onChanged: widget.viewModel.setDraft,
            minLines: 1,
            maxLines: 5,
            maxLength: 16000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: widget.strings.placeholder,
              border: InputBorder.none,
              filled: false,
              counterText: '',
              contentPadding: EdgeInsets.all(tokens.spacing / 2),
            ),
          ),
          SizedBox(height: tokens.spacing / 2),
          Row(
            children: [
              Expanded(
                child: ChatModelPicker(
                  state: widget.state,
                  viewModel: widget.viewModel,
                  strings: widget.strings,
                ),
              ),
              SizedBox(width: tokens.spacing),
              ChatSendAction(
                state: widget.state,
                viewModel: widget.viewModel,
                strings: widget.strings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
