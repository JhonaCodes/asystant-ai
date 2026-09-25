import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  bool _isFocused = false;

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed &&
        !_text.value.composing.isValid) {
      if (widget.viewModel.canSend) widget.viewModel.send();
      return .handled;
    }
    return .ignored;
  }

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
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        AnimatedContainer(
          duration: tokens.transitionDuration,
          padding: EdgeInsets.all(tokens.spacing / 2),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isFocused ? colors.primary : colors.outlineVariant,
              width: _isFocused ? tokens.progressStrokeWidth : 1,
            ),
            color: colors.surface,
            borderRadius: BorderRadius.circular(tokens.composerRadius),
          ),
          child: Row(
            crossAxisAlignment: .end,
            children: [
              Expanded(
                child: Focus(
                  onFocusChange: (focused) =>
                      setState(() => _isFocused = focused),
                  onKeyEvent: _handleKey,
                  child: _ComposerTextField(
                    controller: _text,
                    viewModel: widget.viewModel,
                    strings: widget.strings,
                  ),
                ),
              ),
              ChatSendAction(
                state: widget.state,
                viewModel: widget.viewModel,
                strings: widget.strings,
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: tokens.spacing / 2),
          child: ChatModelPicker(
            state: widget.state,
            viewModel: widget.viewModel,
            strings: widget.strings,
          ),
        ),
      ],
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
    maxLines: 4,
    textInputAction: .newline,
    maxLength: 16000,
    textCapitalization: .sentences,
    decoration: InputDecoration(
      hintText: strings.placeholder,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      isDense: true,
      filled: false,
      counterText: '',
      contentPadding: EdgeInsets.symmetric(
        horizontal: AsystantTheme.of(context).spacing,
        vertical: AsystantTheme.of(context).spacing,
      ),
    ),
  );
}
