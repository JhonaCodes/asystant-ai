import 'package:asystant_core/asystant_core.dart';
import 'package:collection/collection.dart';

import 'package:asystant_ai/src/model/chat_entry.dart';
import 'package:asystant_ai/src/model/conversation_summary.dart';

/// What the store keeps of a conversation that is not on screen.
class ConversationSnapshot {
  const ConversationSnapshot({
    required this.summary,
    this.messages = const [],
    this.entries = const [],
  });

  final ConversationSummary summary;

  /// The provider transcript, tool calls and results included.
  final List<AssistantMessage> messages;

  /// What the chat shows, in order.
  final List<ChatEntry> entries;

  ConversationSnapshot copyWith({
    ConversationSummary? summary,
    List<AssistantMessage>? messages,
    List<ChatEntry>? entries,
  }) => ConversationSnapshot(
    summary: summary ?? this.summary,
    messages: List.unmodifiable(messages ?? this.messages),
    entries: List.unmodifiable(entries ?? this.entries),
  );

  @override
  bool operator ==(Object other) =>
      other is ConversationSnapshot &&
      summary == other.summary &&
      const ListEquality<AssistantMessage>().equals(messages, other.messages) &&
      const ListEquality<ChatEntry>().equals(entries, other.entries);

  @override
  int get hashCode =>
      Object.hash(summary, Object.hashAll(messages), Object.hashAll(entries));
}
