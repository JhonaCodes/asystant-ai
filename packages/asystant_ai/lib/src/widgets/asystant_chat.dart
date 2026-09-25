import 'package:asystant_ai/src/widgets/asystant_glyph.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'package:asystant_ai/src/widgets/asystant_card_content.dart';
import 'package:asystant_ai/src/asystant_ai.dart';
import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/service/asystant_link_opener.dart';
import 'package:asystant_ai/src/viewmodel/chat_view_model.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/widgets/chat_header.dart';
import 'package:asystant_ai/src/widgets/chat_conversation.dart';
import 'package:asystant_ai/src/widgets/chat_composer.dart';
import 'package:asystant_ai/src/widgets/asystant_link_scope.dart';

/// One bounded chat section for sheets, drawers, embedded panels and full screens.
class AsystantChat extends StatefulWidget {
  const AsystantChat({
    super.key,
    required this.assistant,
    this.onClose,
    this.strings,
    this.onOpenLink,
    this.cardContentBuilder,
  });

  final AsystantAI assistant;

  /// Adds typed, host-owned content to completed cards only.
  final AsystantCardContentBuilder? cardContentBuilder;

  final VoidCallback? onClose;

  final AsystantStrings? strings;

  /// Overrides HTTP(S) link navigation. Return false to show localized feedback.
  /// Links open only after an explicit tap; custom URL schemes are rejected.
  final AsystantLinkCallback? onOpenLink;

  @override
  State<AsystantChat> createState() => _AsystantChatState();
}

class _AsystantChatState extends State<AsystantChat> {
  @override
  void initState() {
    super.initState();
    _initializeAfterFrame();
  }

  @override
  void didUpdateWidget(covariant AsystantChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assistant != widget.assistant) {
      _initializeAfterFrame();
    }
  }

  void _initializeAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(widget.assistant.ensureInitialized());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    final labels = widget.strings ?? AsystantStrings.of(context);
    return AsystantLinkScope(
      opener: AsystantLinkOpener(onOpenLink: widget.onOpenLink),
      strings: labels,
      child: Material(
        textStyle: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(height: 1.5),
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: ReactiveViewModelBuilder<ChatViewModel, ChatState>(
            viewmodel: widget.assistant.conversation.notifier,
            build: (state, vm, keep) => Column(
              children: [
                ChatHeader(
                  name: widget.assistant.name,
                  phase: state.phase,
                  strings: labels,
                  onClose: widget.onClose,
                ),
                const Divider(height: 1),
                if (!vm.isInitialized &&
                    (state.phase == ChatPhase.idle ||
                        state.phase == ChatPhase.error))
                  Padding(
                    padding: EdgeInsets.all(tokens.spacing),
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          unawaited(widget.assistant.ensureInitialized()),
                      icon: const AsystantGlyph(AsystantGlyphKind.refresh),
                      label: Text(labels.connect),
                    ),
                  ),
                Expanded(
                  child: Align(
                    alignment: .topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: tokens.maxContentWidth,
                      ),
                      child: ChatConversation(
                        cardContentBuilder: widget.cardContentBuilder,
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
                    constraints: BoxConstraints(
                      maxWidth: tokens.maxContentWidth,
                    ),
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
      ),
    );
  }
}
