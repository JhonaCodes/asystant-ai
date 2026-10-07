import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/asystant_composer_layout.dart';
import 'package:asystant_ai/src/model/asystant_composer_action_placement.dart';
import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/service/asystant_file_picker.dart';
import 'package:asystant_ai/src/theme/asystant_device_type.dart';
import 'package:asystant_ai/src/theme/asystant_metrics.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/viewmodel/chat_view_model.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:asystant_ai/src/widgets/asystant_secret_attachment_sheet.dart';
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
    this.enablePrivateValueAttachment = false,
    this.attachmentActionPlacement = AsystantComposerActionPlacement.inside,
    this.privateValueActionPlacement = AsystantComposerActionPlacement.inside,
    this.layout = AsystantComposerLayout.stacked,
    this.header,
  });

  final ChatState state;

  final ChatViewModel viewModel;

  final AsystantStrings strings;

  /// The files this chat accepts.
  final AsystantAttachmentPolicy attachments;

  /// Replaces the system file picker.
  final AsystantFilePick? onPickFiles;

  /// Whether the optional private-value sheet is available beside files.
  final bool enablePrivateValueAttachment;
  final AsystantComposerActionPlacement attachmentActionPlacement;
  final AsystantComposerActionPlacement privateValueActionPlacement;

  final AsystantComposerLayout layout;

  final Widget? header;

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

  void _pickAttachments() => unawaited(
    widget.viewModel.pickAttachments(
      policy: widget.attachments,
      picker: widget.onPickFiles,
    ),
  );

  /// On phones the keyboard steps aside so the answer is visible.
  void _send() {
    if (context.asystantDeviceType == AsystantDeviceType.mobile) {
      _focus.unfocus();
    }
    unawaited(widget.viewModel.send());
  }

  Future<void> _attachPrivateValue() async {
    final entry = await showAsystantSecretAttachmentSheet(
      context,
      strings: widget.strings,
    );
    if (!mounted || entry == null || !widget.viewModel.canType) return;
    final reference = widget.viewModel.reserveSecret(entry.value);
    if (reference == null) return;
    final current = _text.value;
    final selection = current.selection;
    final validSelection =
        selection.isValid &&
        selection.start <= current.text.length &&
        selection.end <= current.text.length;
    final start = validSelection ? selection.start : current.text.length;
    final end = validSelection ? selection.end : current.text.length;
    final before = current.text.substring(0, start);
    final after = current.text.substring(end);
    final leading = before.isNotEmpty && !RegExp(r'\s$').hasMatch(before)
        ? ' '
        : '';
    final trailing = after.isNotEmpty && !RegExp(r'^\s').hasMatch(after)
        ? ' '
        : '';
    final inserted = '$leading${entry.label}: $reference$trailing';
    final draft = '$before$inserted$after';
    _text.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(
        offset: before.length + inserted.length,
      ),
    );
    widget.viewModel.setDraft(draft);
    _focus.requestFocus();
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
              if (widget.header case final header?) ...[
                header,
                const SizedBox(height: 8),
              ],
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
              if (widget.layout == AsystantComposerLayout.inline)
                _InlineComposer(
                  state: widget.state,
                  viewModel: widget.viewModel,
                  strings: widget.strings,
                  attachments: widget.attachments,
                  onAttach: _pickAttachments,
                  controller: _text,
                  focusNode: _focus,
                  onFocusChange: (focused) =>
                      setState(() => _isFocused = focused),
                  onKeyEvent: _handleKey,
                  onSend: _send,
                  onAttachPrivateValue: _attachPrivateValue,
                  enablePrivateValueAttachment:
                      widget.enablePrivateValueAttachment,
                  attachmentActionPlacement: widget.attachmentActionPlacement,
                  privateValueActionPlacement:
                      widget.privateValueActionPlacement,
                  focused: _isFocused,
                )
              else
                Row(
                  children: [
                    _PlacedComposerActions(
                      placement: .outside,
                      attachments: widget.attachments,
                      attachmentPlacement: widget.attachmentActionPlacement,
                      offersPrivateValue: widget.enablePrivateValueAttachment,
                      privateValuePlacement: widget.privateValueActionPlacement,
                      strings: widget.strings,
                      enabled: canType,
                      onAttach: _pickAttachments,
                      onAttachPrivateValue: _attachPrivateValue,
                    ),
                    Expanded(
                      child: AnimatedContainer(
                        duration: AsystantTheme.of(context).transitionDuration,
                        padding: EdgeInsets.all(metrics.composerInnerPadding),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                          border: Border.all(
                            color: _isFocused
                                ? colors.primary
                                : colors.outlineVariant,
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
                                _PlacedComposerActions(
                                  placement: .inside,
                                  attachments: widget.attachments,
                                  attachmentPlacement:
                                      widget.attachmentActionPlacement,
                                  offersPrivateValue:
                                      widget.enablePrivateValueAttachment,
                                  privateValuePlacement:
                                      widget.privateValueActionPlacement,
                                  strings: widget.strings,
                                  enabled: canType,
                                  onAttach: _pickAttachments,
                                  onAttachPrivateValue: _attachPrivateValue,
                                  fixedTarget: false,
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
                    ),
                  ],
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

class _InlineComposer extends StatelessWidget {
  const _InlineComposer({
    required this.state,
    required this.viewModel,
    required this.strings,
    required this.attachments,
    required this.onAttach,
    required this.controller,
    required this.focusNode,
    required this.onFocusChange,
    required this.onKeyEvent,
    required this.onSend,
    required this.onAttachPrivateValue,
    required this.enablePrivateValueAttachment,
    required this.attachmentActionPlacement,
    required this.privateValueActionPlacement,
    required this.focused,
  });

  final ChatState state;
  final ChatViewModel viewModel;
  final AsystantStrings strings;
  final AsystantAttachmentPolicy attachments;
  final VoidCallback onAttach;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<bool> onFocusChange;
  final FocusOnKeyEventCallback onKeyEvent;
  final VoidCallback onSend;
  final VoidCallback onAttachPrivateValue;
  final bool enablePrivateValueAttachment;
  final AsystantComposerActionPlacement attachmentActionPlacement;
  final AsystantComposerActionPlacement privateValueActionPlacement;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        _PlacedComposerActions(
          placement: .outside,
          attachments: attachments,
          attachmentPlacement: attachmentActionPlacement,
          offersPrivateValue: enablePrivateValueAttachment,
          privateValuePlacement: privateValueActionPlacement,
          strings: strings,
          enabled: viewModel.canType,
          onAttach: onAttach,
          onAttachPrivateValue: onAttachPrivateValue,
        ),
        Expanded(
          child: AnimatedContainer(
            duration: AsystantTheme.of(context).transitionDuration,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              border: Border.all(
                color: focused ? colors.primary : colors.outlineVariant,
                width: focused ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                _PlacedComposerActions(
                  placement: .inside,
                  attachments: attachments,
                  attachmentPlacement: attachmentActionPlacement,
                  offersPrivateValue: enablePrivateValueAttachment,
                  privateValuePlacement: privateValueActionPlacement,
                  strings: strings,
                  enabled: viewModel.canType,
                  onAttach: onAttach,
                  onAttachPrivateValue: onAttachPrivateValue,
                ),
                Expanded(
                  child: Focus(
                    onFocusChange: onFocusChange,
                    onKeyEvent: onKeyEvent,
                    child: _ComposerTextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: viewModel.canType,
                      viewModel: viewModel,
                      strings: strings,
                    ),
                  ),
                ),
                ChatModelPicker(
                  state: state,
                  viewModel: viewModel,
                  strings: strings,
                ),
                ChatSendAction(
                  state: state,
                  viewModel: viewModel,
                  strings: strings,
                  onSend: onSend,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The attach and private-value buttons the host placed at [placement].
class _PlacedComposerActions extends StatelessWidget {
  const _PlacedComposerActions({
    required this.placement,
    required this.attachments,
    required this.attachmentPlacement,
    required this.offersPrivateValue,
    required this.privateValuePlacement,
    required this.strings,
    required this.enabled,
    required this.onAttach,
    required this.onAttachPrivateValue,
    this.fixedTarget = true,
  });

  final AsystantComposerActionPlacement placement;
  final AsystantAttachmentPolicy attachments;
  final AsystantComposerActionPlacement attachmentPlacement;
  final bool offersPrivateValue;
  final AsystantComposerActionPlacement privateValuePlacement;
  final AsystantStrings strings;

  /// Off while the person cannot type; the buttons stay visible, disabled.
  final bool enabled;
  final VoidCallback onAttach;
  final VoidCallback onAttachPrivateValue;

  /// See [_ComposerIconAction.fixedTarget].
  final bool fixedTarget;

  bool get _showsAttach =>
      attachments.enabled && attachmentPlacement == placement;

  bool get _showsPrivateValue =>
      offersPrivateValue && privateValuePlacement == placement;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
      if (_showsAttach)
        _ComposerIconAction(
          icon: AsystantGlyphKind.attach,
          tooltip: strings.attach,
          onPressed: enabled ? onAttach : null,
          fixedTarget: fixedTarget,
        ),
      if (_showsPrivateValue)
        _ComposerIconAction(
          icon: AsystantGlyphKind.key,
          tooltip: strings.privateValueTitle,
          onPressed: enabled ? onAttachPrivateValue : null,
          fixedTarget: fixedTarget,
        ),
    ],
  );
}

class _ComposerIconAction extends StatelessWidget {
  const _ComposerIconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.fixedTarget,
  });

  final AsystantGlyphKind icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Pins a 40 dp box with 8 dp padding; off keeps the IconButton defaults.
  final bool fixedTarget;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    constraints: fixedTarget
        ? const BoxConstraints(minWidth: 40, minHeight: 40)
        : null,
    padding: fixedTarget ? const EdgeInsets.all(8) : null,
    onPressed: onPressed,
    icon: AsystantGlyph(
      icon,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
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
    if (state.attachmentIssue == null &&
        state.pending == null &&
        state.attachments.isEmpty) {
      return const SizedBox.shrink();
    }
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
