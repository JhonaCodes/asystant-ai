import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/viewmodel/chat_view_model.dart';
import 'package:asystant_ai/src/widgets/chat_model_picker.dart';
import 'package:asystant_ai/src/widgets/chat_send_action.dart';

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
    if (_text.text != widget.state.draft) {
      _text.value = TextEditingValue(
        text: widget.state.draft,
        selection: TextSelection.collapsed(offset: widget.state.draft.length),
      );
    }
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
        color: colors.surface,
        borderRadius: BorderRadius.circular(tokens.radius),
      ),
      child: Column(
        mainAxisSize: .min,
        children: [
          _ComposerTextField(
            controller: _text,
            viewModel: widget.viewModel,
            strings: widget.strings,
          ),
          SizedBox(height: tokens.spacing / 2),
          _ComposerActions(
            state: widget.state,
            viewModel: widget.viewModel,
            strings: widget.strings,
          ),
        ],
      ),
    );
  }
}

class _ComposerTextField extends StatelessWidget {
  const _ComposerTextField({
    required this.controller,
    required this.viewModel,
    required this.strings,
  });

  final TextEditingController controller;

  final ChatViewModel viewModel;

  final AsystantStrings strings;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    style: Theme.of(context).textTheme.bodyMedium,
    onChanged: viewModel.setDraft,
    minLines: 1,
    maxLines: 5,
    maxLength: 16000,
    textCapitalization: .sentences,
    decoration: InputDecoration(
      hintText: strings.placeholder,
      border: InputBorder.none,
      filled: false,
      counterText: '',
      contentPadding: EdgeInsets.all(AsystantTheme.of(context).spacing / 2),
    ),
  );
}

class _ComposerActions extends StatelessWidget {
  const _ComposerActions({
    required this.state,
    required this.viewModel,
    required this.strings,
  });

  final ChatState state;

  final ChatViewModel viewModel;

  final AsystantStrings strings;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: ChatModelPicker(
          state: state,
          viewModel: viewModel,
          strings: strings,
        ),
      ),
      SizedBox(width: AsystantTheme.of(context).spacing),
      ChatSendAction(state: state, viewModel: viewModel, strings: strings),
    ],
  );
}
