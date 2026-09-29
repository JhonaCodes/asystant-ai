import 'dart:async';

import 'package:asystant_core/asystant_core.dart';
import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'package:asystant_ai/src/asystant_ai.dart';
import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/asystant_host_card.dart';
import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/service/asystant_file_picker.dart';
import 'package:asystant_ai/src/service/asystant_link_opener.dart';
import 'package:asystant_ai/src/theme/asystant_metrics.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/viewmodel/chat_view_model.dart';
import 'package:asystant_ai/src/widgets/asystant_card_content.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:asystant_ai/src/widgets/asystant_link_scope.dart';
import 'package:asystant_ai/src/widgets/chat_composer.dart';
import 'package:asystant_ai/src/widgets/chat_confirm_dialog.dart';
import 'package:asystant_ai/src/widgets/chat_conversation.dart';
import 'package:asystant_ai/src/widgets/chat_conversation_list.dart';
import 'package:asystant_ai/src/widgets/chat_header.dart';

/// One bounded chat for sheets, side panels, embedded sections and full
/// screens, with its list of conversations.
///
/// It handles the keyboard itself, so hosts must not pad for it.
class AsystantChat extends StatefulWidget {
  const AsystantChat({
    super.key,
    required this.assistant,
    this.onClose,
    this.strings,
    this.onOpenLink,
    this.cardContentBuilder,
    this.isExpanded = false,
    this.onToggleExpansion,
    this.showsHandle = false,
    this.attachments,
    this.onPickFiles,
    this.hostCards = const [],
    this.headerContent,
    this.managesConversations = true,
  });

  final AsystantAI assistant;

  /// Cards the host pins after the conversation, with its own buttons: a
  /// decision its workflow waits for, or a notice. See [AsystantHostCard].
  final List<AsystantHostCard> hostCards;

  /// Host content under the header, such as what the assistant is working
  /// on right now. It stays in place while the conversation scrolls.
  final Widget? headerContent;

  /// Whether the chat offers the conversation list, a new conversation and
  /// deleting one. Turn it off when the host keeps one conversation per
  /// context (for example one per open document) and switches it itself
  /// with `openConversation`.
  final bool managesConversations;

  /// Adds typed, host-owned content to completed cards only.
  final AsystantCardContentBuilder? cardContentBuilder;

  final VoidCallback? onClose;

  final AsystantStrings? strings;

  /// Overrides HTTP(S) link navigation. Return false to show localized feedback.
  /// Links open only after an explicit tap; custom URL schemes are rejected.
  final AsystantLinkCallback? onOpenLink;

  /// The expand button reflects this; the host owns the panel's width.
  final bool isExpanded;

  /// Shows the expand button when set.
  final VoidCallback? onToggleExpansion;

  /// Draws a drag handle on top, for bottom sheets.
  final bool showsHandle;

  /// The files this chat accepts; the assistant's policy when null.
  final AsystantAttachmentPolicy? attachments;

  /// Replaces the system file picker, e.g. with a camera or scanner.
  final AsystantFilePick? onPickFiles;

  @override
  State<AsystantChat> createState() => _AsystantChatState();
}

class _AsystantChatState extends State<AsystantChat> {
  bool _listOpen = false;

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

  void _showList(bool open) => setState(() => _listOpen = open);

  Future<void> _delete(AsystantStrings strings, String id) async {
    final confirmed = await showChatConfirmDialog(
      context,
      strings: strings,
      title: strings.deleteTitle,
      body: strings.deleteBody,
      confirmLabel: strings.delete,
    );
    if (confirmed && mounted) {
      await widget.assistant.conversation.notifier.deleteConversation(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.strings ?? AsystantStrings.of(context);
    final tokens = AsystantTheme.of(context);
    return AsystantLinkScope(
      opener: AsystantLinkOpener(onOpenLink: widget.onOpenLink),
      strings: labels,
      child: Material(
        textStyle: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(height: 1.5),
        color: Theme.of(context).colorScheme.surface,
        child: _KeyboardInset(
          child: SafeArea(
            // Density follows the chat's own width, not the device class.
            child: LayoutBuilder(
              builder: (context, constraints) => AsystantMetricsScope(
                metrics: tokens.metricsFor(constraints.maxWidth),
                child: PopScope(
                  canPop: !_listOpen,
                  onPopInvokedWithResult: (didPop, _) {
                    if (!didPop) {
                      _showList(false);
                    }
                  },
                  child: ReactiveViewModelBuilder<ChatViewModel, ChatState>(
                    viewmodel: widget.assistant.conversation.notifier,
                    build: (state, vm, keep) => _ChatLayout(
                      sideList:
                          widget.managesConversations &&
                          widget.isExpanded &&
                          constraints.maxWidth >= tokens.sideListFromWidth,
                      listOpen: _listOpen,
                      onShowList: _showList,
                      chat: widget,
                      state: state,
                      viewModel: vm,
                      strings: labels,
                      onDelete: (id) => _delete(labels, id),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Header, messages and composer, with the conversation list beside them
/// (a wide expanded chat) or over them (when opened).
class _ChatLayout extends StatelessWidget {
  const _ChatLayout({
    required this.sideList,
    required this.listOpen,
    required this.onShowList,
    required this.chat,
    required this.state,
    required this.viewModel,
    required this.strings,
    required this.onDelete,
  });

  final bool sideList;

  final bool listOpen;

  final ValueChanged<bool> onShowList;

  final AsystantChat chat;

  final ChatState state;

  final ChatViewModel viewModel;

  final AsystantStrings strings;

  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final assistant = chat.assistant;
    final manages = chat.managesConversations;
    final column = Column(
      children: [
        ChatHeader(
          name: assistant.name,
          description: assistant.description,
          state: state,
          strings: strings,
          canManage: viewModel.canManageConversations,
          showsHandle: chat.showsHandle,
          isExpanded: chat.isExpanded,
          onToggleExpansion: chat.onToggleExpansion,
          onHistory: manages && !sideList ? () => onShowList(true) : null,
          onNew: manages ? viewModel.newConversation : null,
          onDelete: manages ? () => onDelete(state.conversationId) : null,
          onClose: chat.onClose,
        ),
        ?chat.headerContent,
        const Divider(height: 1),
        if (!viewModel.isInitialized &&
            (state.phase == ChatPhase.idle || state.phase == ChatPhase.error))
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: () => unawaited(assistant.ensureInitialized()),
              icon: const AsystantGlyph(AsystantGlyphKind.refresh),
              label: Text(strings.connect),
            ),
          ),
        Expanded(
          child: Align(
            alignment: .topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AsystantTheme.of(context).maxContentWidth,
              ),
              child: ChatConversation(
                name: assistant.name,
                cardContentBuilder: chat.cardContentBuilder,
                hostCards: chat.hostCards,
                state: state,
                viewModel: viewModel,
                strings: strings,
                onStartNew: manages ? viewModel.newConversation : null,
              ),
            ),
          ),
        ),
        ChatComposer(
          state: state,
          viewModel: viewModel,
          strings: strings,
          attachments: chat.attachments ?? viewModel.attachmentPolicy,
          onPickFiles: chat.onPickFiles,
        ),
      ],
    );
    if (sideList) {
      return Row(
        children: [
          SizedBox(
            width: AsystantTheme.of(context).sideListWidth,
            child: _BoundConversationList(
              state: state,
              viewModel: viewModel,
              strings: strings,
              onDelete: onDelete,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: column),
        ],
      );
    }
    return Stack(
      children: [
        column,
        if (listOpen)
          Positioned.fill(
            child: ChatConversationLayer(
              onDismiss: () => onShowList(false),
              list: _BoundConversationList(
                state: state,
                viewModel: viewModel,
                strings: strings,
                onDelete: onDelete,
                onBack: () => onShowList(false),
              ),
            ),
          ),
      ],
    );
  }
}

/// The conversation list wired to the view model; opening or starting one
/// also returns to the chat when the list is a layer ([onBack] set).
class _BoundConversationList extends StatelessWidget {
  const _BoundConversationList({
    required this.state,
    required this.viewModel,
    required this.strings,
    required this.onDelete,
    this.onBack,
  });

  final ChatState state;

  final ChatViewModel viewModel;

  final AsystantStrings strings;

  final ValueChanged<String> onDelete;

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => ChatConversationList(
    conversations: state.conversations,
    activeId: state.conversationId,
    strings: strings,
    canManage: viewModel.canManageConversations,
    onOpen: (id) {
      onBack?.call();
      unawaited(viewModel.openConversation(id));
    },
    onDelete: onDelete,
    onNew: () {
      onBack?.call();
      unawaited(viewModel.newConversation());
    },
    onBack: onBack,
  );
}

/// Keeps the chat above the keyboard, once: the space is subtracted here and
/// removed from what the children see, so nothing inside subtracts it again.
class _KeyboardInset extends StatelessWidget {
  const _KeyboardInset({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: child,
    ),
  );
}
