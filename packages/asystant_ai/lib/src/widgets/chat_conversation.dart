import 'dart:async';

import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/asystant_host_card.dart';
import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/presentation/asystant_presentation_registry.dart';
import 'package:asystant_ai/src/theme/asystant_metrics.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/viewmodel/chat_view_model.dart';
import 'package:asystant_ai/src/widgets/asystant_card_content.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:asystant_ai/src/widgets/chat_activity_card.dart';
import 'package:asystant_ai/src/widgets/chat_confirmation_card.dart';
import 'package:asystant_ai/src/widgets/chat_private_input_card.dart';
import 'package:asystant_ai/src/widgets/chat_context_warning.dart';
import 'package:asystant_ai/src/widgets/chat_failure_notice.dart';
import 'package:asystant_ai/src/widgets/chat_message_bubble.dart';
import 'package:asystant_ai/src/widgets/chat_timeline.dart';
import 'package:asystant_ai/src/widgets/chat_welcome.dart';
import 'package:asystant_ai/src/widgets/gen_ui_card.dart';
import 'package:asystant_ai/src/widgets/turn_activity_presentation.dart';

/// The conversation as it is drawn: messages, what each turn did, the turn
/// in progress, and whatever waits for the person.
class ChatConversation extends StatelessWidget {
  const ChatConversation({
    super.key,
    required this.name,
    required this.state,
    required this.viewModel,
    required this.strings,
    required this.onStartNew,
    this.cardContentBuilder,
    this.completedCardBuilder,
    this.presentationRegistry,
    this.hostCards = const [],
    this.welcomeContent,
  });

  /// The assistant's name, shown above its messages.
  final String name;

  final ChatState state;

  final ChatViewModel viewModel;

  final AsystantStrings strings;

  /// Starts a new conversation; null when the host manages conversations
  /// itself, which hides the actions that would start one.
  final VoidCallback? onStartNew;

  final AsystantCardContentBuilder? cardContentBuilder;

  final AsystantCompletedCardBuilder? completedCardBuilder;

  final AsystantPresentationRegistry? presentationRegistry;

  /// The host's cards, pinned after the conversation.
  final List<AsystantHostCard> hostCards;

  /// Host-provided welcome shown in an empty conversation.
  final Widget? welcomeContent;

  /// Whatever waits for the person keeps the timeline at the end.
  bool get _forcesFollow =>
      state.awaitsAnswer ||
      hostCards.any((hostCard) => hostCard.awaitsDecision);

  /// A card's suggested option is sent as a message, never while a turn runs.
  ValueChanged<String>? get _onOptionPressed =>
      state.busy ? null : (option) => unawaited(viewModel.send(option));

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    return ChatTimeline(
      anchor: (state.conversationId, state.sentCount),
      forceFollow: _forcesFollow,
      startAtTop: state.showsWelcome,
      padding: AsystantMetrics.of(context).listPadding,
      children: [
        if (state.showsWelcome) welcomeContent ?? ChatWelcome(strings: strings),
        for (final entry in state.entries) ...[
          if (entry.activity.isNotEmpty)
            ChatActivityCard(
              title: entry.activityHasIssues
                  ? strings.activityWithIssues
                  : strings.activityCompleted,
              subtitle: strings.activityEvents,
              icon: AsystantGlyphKind.activity,
              tone: entry.activityHasIssues
                  ? Theme.of(context).colorScheme.error
                  : tokens.successColor(context),
              steps: entry.activity,
              strings: strings,
            ),
          if (entry.message case final message?
              when message.content.isNotEmpty || message.attachments.isNotEmpty)
            ChatMessageBubble(
              text: message.content,
              fromUser: message.isFromUser,
              author: message.isFromUser ? strings.you : name,
              attachments: message.attachments,
              strings: strings,
            ),
          if (entry.card case final card?)
            presentationRegistry?.build(
                  context,
                  card,
                  strings,
                  _onOptionPressed,
                ) ??
                completedCardBuilder?.call(context, card) ??
                GenUiCard(
                  card: card,
                  strings: strings,
                  content: cardContentBuilder?.call(context, card),
                  onOptionPressed: _onOptionPressed,
                ),
        ],
        if (state.isWriting)
          ChatMessageBubble(
            text: state.streaming,
            fromUser: false,
            author: name,
            strings: strings,
          ),
        if (state.showsLiveActivity)
          _LiveActivity(name: name, state: state, strings: strings),
        for (final hostCard in hostCards)
          GenUiCard(
            card: hostCard.card,
            strings: strings,
            actions: hostCard.actions,
          ),
        if (state.pending case final pending?)
          ChatConfirmationCard(
            pending: pending,
            strings: strings,
            onSelect: viewModel.selectOption,
            onDecide: viewModel.approve,
            onAllowSession: viewModel.approveAllForSession,
          ),
        if (state.privateInput case final request?)
          ChatPrivateInputCard(
            key: ValueKey(request.id),
            request: request,
            strings: strings,
            onSubmit: viewModel.submitPrivateInput,
            onCancel: viewModel.declinePrivateInput,
          ),
        if (state.failure case final failure?)
          ChatFailureNotice(
            failure: failure,
            strings: strings,
            onStartNew: state.needsNewConversation ? onStartNew : null,
          ),
        if ((state.showsContextWarning, onStartNew) case (
          true,
          final startNew?,
        ))
          ChatContextWarning(strings: strings, onStartNew: startNew),
      ],
    );
  }
}

class _LiveActivity extends StatelessWidget {
  const _LiveActivity({
    required this.name,
    required this.state,
    required this.strings,
  });

  final String name;

  final ChatState state;

  final AsystantStrings strings;

  @override
  Widget build(BuildContext context) => ChatActivityCard(
    title: state.turnActivity.toTitle(strings, name),
    subtitle: strings.liveActivity,
    icon: state.turnActivity.toGlyph(),
    steps: state.steps,
    strings: strings,
    live: true,
    closingStep: state.turnActivity.toClosingStep(strings),
  );
}
