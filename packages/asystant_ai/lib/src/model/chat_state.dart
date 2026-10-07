import 'package:asystant_core/asystant_core.dart';
import 'package:collection/collection.dart';

import 'package:asystant_ai/src/model/assistant_step.dart';
import 'package:asystant_ai/src/model/asystant_model_option.dart';
import 'package:asystant_ai/src/model/chat_entry.dart';
import 'package:asystant_ai/src/model/chat_phase.dart';
import 'package:asystant_ai/src/model/context_usage.dart';
import 'package:asystant_ai/src/model/conversation_summary.dart';
import 'package:asystant_ai/src/model/pending_action.dart';
import 'package:asystant_ai/src/model/private_input_request.dart';

export 'package:asystant_ai/src/model/chat_phase.dart';
export 'package:asystant_ai/src/model/context_usage.dart';
export 'package:asystant_ai/src/model/conversation_summary.dart';
export 'package:asystant_ai/src/model/pending_action.dart';

/// The conversation on screen plus the list of the others.
///
/// Only the active conversation's messages live here; the rest wait in the
/// conversation store.
class ChatState {
  const ChatState({
    this.phase = .idle,
    this.messages = const [],
    this.cards = const [],
    this.streaming = '',
    this.draft = '',
    this.pending,
    this.privateInput,
    this.failure,
    this.model = '',
    this.models = const [],
    this.steps = const [],
    this.entries = const [],
    this.allowModelSelection = true,
    this.conversationId = '',
    this.conversations = const [],
    this.usage,
    this.contextLengths = const {},
    this.modelOptions = const [],
    this.attachments = const [],
    this.attachmentIssue,
  });

  final List<AssistantStep> steps;

  final List<ChatEntry> entries;

  final bool allowModelSelection;

  final ChatPhase phase;

  final List<AssistantMessage> messages;

  final List<AssistantCard> cards;

  final String streaming;

  final String draft;

  final PendingAction? pending;
  final PrivateInputRequest? privateInput;

  final AssistantFailure? failure;

  final String model;

  final List<String> models;

  final String conversationId;

  /// Every conversation with messages, the most recent first.
  final List<ConversationSummary> conversations;

  /// The provider's latest count for the active conversation.
  final TokenUsage? usage;

  /// Context window per model, when the provider reports it.
  final Map<String, int> contextLengths;

  /// How the host names and draws each allowed model.
  final List<AsystantModelOption> modelOptions;

  /// Files waiting in the composer for the next message.
  final List<AsystantAttachment> attachments;

  /// Why the last file was not attached.
  final AttachmentIssue? attachmentIssue;

  /// Every file attached in this conversation, for local tools.
  List<AsystantAttachment> get conversationAttachments => [
    for (final message in messages) ...message.attachments,
  ];

  /// The host's name for [model], or its short id.
  String labelOf(String model) => optionOf(model).label;

  /// The host's option for [model], or a plain one from its id.
  AsystantModelOption optionOf(String model) =>
      modelOptions.firstWhereOrNull((option) => option.id == model) ??
      AsystantModelOption.fallback(model);

  /// Whether the person may switch models: allowed and more than one.
  bool get offersModelChoice => allowModelSelection && modelOptions.length > 1;

  /// The conversation no longer fits the model; only a new one helps.
  bool get needsNewConversation => failure?.code == FailureCode.contextFull;

  /// How many messages the person has sent in this conversation.
  int get sentCount =>
      entries.where((entry) => entry.message?.isFromUser ?? false).length;

  bool get busy => switch (phase) {
    ChatPhase.thinking || ChatPhase.executing || ChatPhase.permission => true,
    ChatPhase.idle ||
    ChatPhase.initializing ||
    ChatPhase.ready ||
    ChatPhase.done ||
    ChatPhase.canceled ||
    ChatPhase.error => false,
  };

  /// The header shows the live status only while something is happening
  /// or needs attention; at rest it shows the host's description.
  bool get showsStatus => switch (phase) {
    ChatPhase.initializing ||
    ChatPhase.thinking ||
    ChatPhase.executing ||
    ChatPhase.permission ||
    ChatPhase.error => true,
    ChatPhase.idle ||
    ChatPhase.ready ||
    ChatPhase.done ||
    ChatPhase.canceled => false,
  };

  /// A turn runs or setup is underway, so the provider cannot change now.
  bool get isBusyOrInitializing => busy || phase == ChatPhase.initializing;

  /// Whether there is a conversation to replace or delete.
  bool get hasConversation => messages.isNotEmpty;

  /// An approval or a private value waits for the person's answer.
  bool get awaitsAnswer => pending != null || privateInput != null;

  /// The empty conversation shows the welcome while no turn runs.
  bool get showsWelcome => entries.isEmpty && !busy;

  /// Whether the model is writing text right now.
  bool get isWriting => streaming.isNotEmpty;

  /// The activity of the turn in progress, while it runs.
  bool get showsLiveActivity =>
      pending == null &&
      privateInput == null &&
      (phase == ChatPhase.thinking || phase == ChatPhase.executing);

  /// What the live activity card says the assistant is doing.
  TurnActivity get turnActivity => switch (this) {
    ChatState(isWriting: true) => TurnActivity.writing,
    ChatState(phase: ChatPhase.executing) => TurnActivity.usingTool,
    _ => TurnActivity.thinking,
  };

  /// Every response re-sends the whole conversation, so the latest total is
  /// what the conversation occupies; adding the counts would count it twice.
  /// Null while neither the usage nor the model's window is known.
  ContextUsage? get contextUsage {
    final limit = contextLengths[model];
    if (usage == null && limit == null) {
      return null;
    }
    return ContextUsage(used: usage?.totalTokens ?? 0, limit: limit);
  }

  /// Suggest a new conversation once the window is nearly full.
  bool get showsContextWarning =>
      !busy && !needsNewConversation && (contextUsage?.isAlmostFull ?? false);

  ChatState copyWith({
    List<AssistantStep>? steps,
    List<ChatEntry>? entries,
    bool? allowModelSelection,
    ChatPhase? phase,
    List<AssistantMessage>? messages,
    List<AssistantCard>? cards,
    String? streaming,
    String? draft,
    PendingAction? pending,
    bool clearPending = false,
    PrivateInputRequest? privateInput,
    bool clearPrivateInput = false,
    AssistantFailure? failure,
    bool clearFailure = false,
    String? model,
    List<String>? models,
    String? conversationId,
    List<ConversationSummary>? conversations,
    TokenUsage? usage,
    bool clearUsage = false,
    Map<String, int>? contextLengths,
    List<AsystantModelOption>? modelOptions,
    List<AsystantAttachment>? attachments,
    AttachmentIssue? attachmentIssue,
    bool clearAttachmentIssue = false,
  }) => ChatState(
    steps: List.unmodifiable(steps ?? this.steps),
    entries: List.unmodifiable(entries ?? this.entries),
    allowModelSelection: allowModelSelection ?? this.allowModelSelection,
    phase: phase ?? this.phase,
    messages: List.unmodifiable(messages ?? this.messages),
    cards: List.unmodifiable(cards ?? this.cards),
    streaming: streaming ?? this.streaming,
    draft: draft ?? this.draft,
    pending: clearPending ? null : pending ?? this.pending,
    privateInput: clearPrivateInput ? null : privateInput ?? this.privateInput,
    failure: clearFailure ? null : failure ?? this.failure,
    model: model ?? this.model,
    models: List.unmodifiable(models ?? this.models),
    conversationId: conversationId ?? this.conversationId,
    conversations: List.unmodifiable(conversations ?? this.conversations),
    usage: clearUsage ? null : usage ?? this.usage,
    contextLengths: Map.unmodifiable(contextLengths ?? this.contextLengths),
    modelOptions: List.unmodifiable(modelOptions ?? this.modelOptions),
    attachments: List.unmodifiable(attachments ?? this.attachments),
    attachmentIssue: clearAttachmentIssue
        ? null
        : attachmentIssue ?? this.attachmentIssue,
  );

  List<Object?> get _fields => [
    steps,
    entries,
    allowModelSelection,
    phase,
    messages,
    cards,
    streaming,
    draft,
    pending,
    privateInput,
    failure,
    model,
    models,
    conversationId,
    conversations,
    usage,
    contextLengths,
    modelOptions,
    attachments,
    attachmentIssue,
  ];

  @override
  bool operator ==(Object other) =>
      other is ChatState &&
      const DeepCollectionEquality().equals(_fields, other._fields);

  @override
  int get hashCode => const DeepCollectionEquality().hash(_fields);
}

/// What the assistant is doing during a turn.
enum TurnActivity { thinking, writing, usingTool }
