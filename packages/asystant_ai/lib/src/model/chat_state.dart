import 'package:asystant_core/asystant_core.dart';
import 'package:collection/collection.dart';

import 'package:asystant_ai/src/model/assistant_step.dart';
import 'package:asystant_ai/src/model/chat_entry.dart';
import 'package:asystant_ai/src/model/chat_phase.dart';
import 'package:asystant_ai/src/model/pending_action.dart';

export 'package:asystant_ai/src/model/chat_phase.dart';
export 'package:asystant_ai/src/model/pending_action.dart';

/// Ephemeral view state; only the transport serializes conversation messages.
class ChatState {
  const ChatState({
    this.phase = .idle,
    this.messages = const [],
    this.cards = const [],
    this.streaming = '',
    this.draft = '',
    this.pending,
    this.failure,
    this.model = '',
    this.models = const [],
    this.steps = const [],
    this.entries = const [],
    this.allowModelSelection = true,
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

  final AssistantFailure? failure;

  final String model;

  final List<String> models;

  bool get busy => switch (phase) {
    ChatPhase.thinking || ChatPhase.executing || ChatPhase.permission => true,
    ChatPhase.idle ||
    ChatPhase.initializing ||
    ChatPhase.ready ||
    ChatPhase.done ||
    ChatPhase.canceled ||
    ChatPhase.error => false,
  };

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
    AssistantFailure? failure,
    bool clearFailure = false,
    String? model,
    List<String>? models,
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
    failure: clearFailure ? null : failure ?? this.failure,
    model: model ?? this.model,
    models: List.unmodifiable(models ?? this.models),
  );

  @override
  bool operator ==(Object other) =>
      other is ChatState &&
      const DeepCollectionEquality().equals(
        [
          steps,
          entries,
          allowModelSelection,
          phase,
          messages,
          cards,
          streaming,
          draft,
          pending,
          failure,
          model,
          models,
        ],
        [
          other.steps,
          other.entries,
          other.allowModelSelection,
          other.phase,
          other.messages,
          other.cards,
          other.streaming,
          other.draft,
          other.pending,
          other.failure,
          other.model,
          other.models,
        ],
      );

  @override
  int get hashCode => const DeepCollectionEquality().hash([
    steps,
    entries,
    allowModelSelection,
    phase,
    messages,
    cards,
    streaming,
    draft,
    pending,
    failure,
    model,
    models,
  ]);
}
