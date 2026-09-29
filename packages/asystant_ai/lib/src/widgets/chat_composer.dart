import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/service/asystant_file_picker.dart';
import 'package:asystant_ai/src/theme/asystant_device_type.dart';
import 'package:asystant_ai/src/theme/asystant_metrics.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/viewmodel/chat_view_model.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:asystant_ai/src/widgets/chat_context_meter.dart';
import 'package:asystant_ai/src/widgets/chat_message_bubble.dart';
import 'package:asystant_ai/src/widgets/chat_model_picker.dart';
import 'package:asystant_ai/src/widgets/chat_send_action.dart';
import 'package:asystant_core/asystant_core.dart';

/// Controllers are widget lifecycle resources; conversation state lives in the VM.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.state,
    required this.viewModel,
    required this.strings,
    required this.attachments,
    this.onPickFiles,
  });

  final ChatState state;

  final ChatViewModel viewModel;

  final AsystantStrings strings;

  /// The files this chat accepts.
  final AsystantAttachmentPolicy attachments;

  /// Replaces the system file picker.
  final AsystantFilePick? onPickFiles;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final TextEditingController _text = TextEditingController();

  final FocusNode _focus = FocusNode();

  bool _isFocused = false;

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed &&
        !_text.value.composing.isValid) {
      if (widget.viewModel.canSend) _send();
      return .handled;
    }
    return .ignored;
  }

  /// On phones the keyboard steps aside so the answer is visible.
  void _send() {
    if (context.asystantDeviceType == AsystantDeviceType.mobile) {
      _focus.unfocus();
    }
    unawaited(widget.viewModel.send());
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
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = AsystantMetrics.of(context);
    final colors = Theme.of(context).colorScheme;
    final canType = widget.viewModel.canType;
    return Container(
      padding: metrics.composerPadding,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AsystantTheme.of(context).maxContentWidth,
          ),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              if (widget.state.attachments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Wrap(
                    spacing: 6,
                    children: [
                      for (final file in widget.state.attachments)
                        ChatAttachmentTile(
                          file: file,
                          strings: widget.strings,
                          onRemove: widget.state.busy
                              ? null
                              : () =>
                                    widget.viewModel.removeAttachment(file.id),
                        ),
                    ],
                  ),
                ),
              AnimatedContainer(
                duration: AsystantTheme.of(context).transitionDuration,
                padding: EdgeInsets.all(metrics.composerInnerPadding),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  border: Border.all(
                    color: _isFocused ? colors.primary : colors.outlineVariant,
                    width: _isFocused ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (_isFocused)
                      BoxShadow(
                        color: colors.primary.withValues(alpha: .12),
                        spreadRadius: 3,
                      ),
                  ],
                ),
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    Focus(
                      onFocusChange: (focused) =>
                          setState(() => _isFocused = focused),
                      onKeyEvent: _handleKey,
                      child: _ComposerTextField(
                        controller: _text,
                        focusNode: _focus,
                        enabled: canType,
                        viewModel: widget.viewModel,
                        strings: widget.strings,
                      ),
                    ),
                    // Attach on the left; the model and Send on the right.
                    Row(
                      children: [
                        if (widget.attachments.enabled)
                          IconButton(
                            tooltip: widget.strings.attach,
                            visualDensity: VisualDensity.compact,
                            onPressed: canType
                                ? () => widget.viewModel.pickAttachments(
                                    policy: widget.attachments,
                                    picker: widget.onPickFiles,
                                  )
                                : null,
                            icon: AsystantGlyph(
                              AsystantGlyphKind.attach,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        const Spacer(),
                        ChatModelPicker(
                          state: widget.state,
                          viewModel: widget.viewModel,
                          strings: widget.strings,
                        ),
                        const SizedBox(width: 4),
                        ChatSendAction(
                          state: widget.state,
                          viewModel: widget.viewModel,
                          strings: widget.strings,
                          onSend: _send,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _ComposerFooter(
                state: widget.state,
                viewModel: widget.viewModel,
                strings: widget.strings,
                attachments: widget.attachments,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerFooter extends StatelessWidget {
  const _ComposerFooter({
    required this.state,
    required this.viewModel,
    required this.strings,
    required this.attachments,
  });

  final ChatState state;

  final ChatViewModel viewModel;

  final AsystantStrings strings;

  final AsystantAttachmentPolicy attachments;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: colors.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          if (state.attachmentIssue case final issue?)
            Text(
              strings.attachmentIssue(issue, attachments),
              style: label?.copyWith(color: colors.error),
            ),
          if (state.pending != null)
            Text(strings.awaitingDecision, style: label)
          else
            SizedBox(
              height: 24,
              child: Row(
                children: [
                  const Spacer(),
                  if (state.attachments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        strings.attachmentCount(
                          state.attachments.length,
                          attachments.maxFiles,
                        ),
                        style: label,
                      ),
                    ),
                  if (state.contextUsage case final usage?)
                    ChatContextMeter(usage: usage, strings: strings),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ComposerTextField extends StatelessWidget {
  const _ComposerTextField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.viewModel,
    required this.strings,
  });

  final TextEditingController controller;

  final FocusNode focusNode;

  /// Off only while an action waits for a decision.
  final bool enabled;

  final ChatViewModel viewModel;

  final AsystantStrings strings;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    focusNode: focusNode,
    enabled: enabled,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    ),
  );
}
