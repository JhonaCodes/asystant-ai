import 'dart:async';

import 'package:asystant_core/asystant_core.dart';
import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'package:asystant_ai/src/asystant_ai.dart';
import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/asystant_conversation_actions_style.dart';
import 'package:asystant_ai/src/model/asystant_composer_layout.dart';
import 'package:asystant_ai/src/model/asystant_composer_action_placement.dart';
import 'package:asystant_ai/src/model/asystant_menu_action.dart';
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
import 'package:asystant_ai/src/widgets/asystant_provider_settings_sheet.dart';

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
    this.completedCardBuilder,
    this.isExpanded = false,
    this.onToggleExpansion,
    this.showsHandle = false,
    this.attachments,
    this.onPickFiles,
    this.enablePrivateValueAttachment = false,
    this.attachmentActionPlacement = AsystantComposerActionPlacement.inside,
    this.privateValueActionPlacement = AsystantComposerActionPlacement.inside,
    this.hostCards = const [],
    this.headerContent,
    this.headerActions = const [],
    this.managesConversations = true,
    this.conversationActionsStyle = AsystantConversationActionsStyle.inline,
    this.conversationMenuIcon,
    this.identityIcon,
    this.welcomeContent,
    this.menuActions = const [],
    this.composerLayout = AsystantComposerLayout.stacked,
    this.composerHeader,
  });

  /// Host buttons in the header row, before the conversation actions, such
  /// as navigation when the chat is the host's main screen.
  final List<Widget> headerActions;

  /// Inline icons or one dropdown menu for the conversation actions.
  final AsystantConversationActionsStyle conversationActionsStyle;

  /// The icon that opens the menu style; a "more" glyph when null.
  final Widget? conversationMenuIcon;

  /// Host identity in the chat header. Defaults to the library glyph.
  final Widget? identityIcon;

  /// Host welcome screen when the conversation is empty.
  final Widget? welcomeContent;

  /// Host navigation and other actions in the conversation menu.
  final List<AsystantMenuAction> menuActions;

  /// Built-in composer layout; inline keeps attachments, model selection and send.
  final AsystantComposerLayout composerLayout;

  /// Host content immediately above the composer field.
  final Widget? composerHeader;

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

  /// Host presentation for a completed domain card, such as a native ticket
  /// row. A null result keeps the built-in structured card.
  final AsystantCompletedCardBuilder? completedCardBuilder;

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

  /// Shows the optional key icon and private-value bottom sheet in the
  /// composer. `$value` text protection works regardless of this setting.
  final bool enablePrivateValueAttachment;

  /// Place the attachment and private-value buttons inside, beside, or hide
  /// them independently. A disabled attachment policy still hides its button.
  final AsystantComposerActionPlacement attachmentActionPlacement;
  final AsystantComposerActionPlacement privateValueActionPlacement;

  @override
  State<AsystantChat> createState() => _AsystantChatState();
}

class _AsystantChatState extends State<AsystantChat> {
  bool _listOpen = false;

  late AsystantStrings _labels;

  @override
  void initState() {
    super.initState();
    _initializeAfterFrame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncStrings();
  }

  @override
  void didUpdateWidget(covariant AsystantChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assistant != widget.assistant) {
      _initializeAfterFrame();
    }
    if (oldWidget.strings != widget.strings ||
        oldWidget.assistant != widget.assistant) {
      _syncStrings();
    }
  }

  /// Resolves the labels and hands them to the view model outside `build()`.
  void _syncStrings() {
    _labels = widget.strings ?? AsystantStrings.of(context);
    widget.assistant.conversation.notifier.setStrings(_labels);
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
    final labels = _labels;
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
    final column = _ChatColumn(
      sideList: sideList,
      onShowList: onShowList,
      chat: chat,
      state: state,
      viewModel: viewModel,
      strings: strings,
      onDelete: onDelete,
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

/// Header, connect prompt, messages and composer, stacked top to bottom.
class _ChatColumn extends StatelessWidget {
  const _ChatColumn({
    required this.sideList,
    required this.onShowList,
    required this.chat,
    required this.state,
    required this.viewModel,
    required this.strings,
    required this.onDelete,
  });

  final bool sideList;

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
    return Column(
      children: [
        ChatHeader(
          name: assistant.name,
          description: assistant.description,
          state: state,
          strings: strings,
          contextUsage: state.contextUsage,
          canManage: viewModel.canManageConversations,
          showsHandle: chat.showsHandle,
          isExpanded: chat.isExpanded,
          onToggleExpansion: chat.onToggleExpansion,
          actions: chat.headerActions,
          actionsStyle: chat.conversationActionsStyle,
          menuIcon: chat.conversationMenuIcon,
          identityIcon: chat.identityIcon,
          menuActions: [
            ...chat.menuActions,
            if (assistant.providerSettings?.showInChatMenu ?? false)
              AsystantMenuAction(
                label: strings.aiSettings,
                icon: Icons.tune,
                onPressed: state.canOpenSettings
                    ? () => showAsystantProviderSettings(
                        context,
                        assistant: assistant,
                        strings: strings,
                      )
                    : null,
              ),
          ],
          onHistory: manages && !sideList ? () => onShowList(true) : null,
          onNew: manages ? viewModel.newConversation : null,
          onDelete: manages ? () => onDelete(state.conversationId) : null,
          onClose: chat.onClose,
        ),
        ?chat.headerContent,
        const Divider(height: 1),
        if (viewModel.offersConnect)
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
                completedCardBuilder: chat.completedCardBuilder,
                presentationRegistry: assistant.presentationRegistry,
                hostCards: chat.hostCards,
                welcomeContent: chat.welcomeContent,
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
          enablePrivateValueAttachment: chat.enablePrivateValueAttachment,
          attachmentActionPlacement: chat.attachmentActionPlacement,
          privateValueActionPlacement: chat.privateValueActionPlacement,
          layout: chat.composerLayout,
          header: chat.composerHeader,
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

// keel-debt: belongs on ChatState (plan M3); private here until WP-5 lands.
extension _ChatStateRules on ChatState {
  /// Provider settings open only while no turn runs and setup is not underway.
  bool get canOpenSettings => !busy && phase != ChatPhase.initializing;
}

// keel-debt: belongs on ChatViewModel; private here while viewmodel/ is frozen.
extension _ChatViewModelRules on ChatViewModel {
  /// The manual connect prompt shows while setup has not run, or after it failed.
  bool get offersConnect =>
      !isInitialized &&
      (state.phase == ChatPhase.idle || state.phase == ChatPhase.error);
}
