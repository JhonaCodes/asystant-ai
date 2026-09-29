import 'package:asystant_core/asystant_core.dart';
import 'package:collection/collection.dart';

import 'package:asystant_ai/src/model/assistant_step.dart';

/// Ephemeral display order, separate from the provider's tool-call transcript.
class ChatEntry {
  const ChatEntry({this.message, this.card, this.activity = const []});

  final AssistantMessage? message;

  final AssistantCard? card;

  /// What the assistant did before [message], when that turn used tools.
  final List<AssistantStep> activity;

  /// Whether any step of [activity] did not complete.
  bool get activityHasIssues => activity.any((step) => step.hasIssue);

  ChatEntry copyWith({
    AssistantMessage? message,
    AssistantCard? card,
    List<AssistantStep>? activity,
  }) => ChatEntry(
    message: message ?? this.message,
    card: card ?? this.card,
    activity: List.unmodifiable(activity ?? this.activity),
  );

  @override
  bool operator ==(Object other) =>
      other is ChatEntry &&
      message == other.message &&
      card == other.card &&
      const ListEquality<AssistantStep>().equals(activity, other.activity);

  @override
  int get hashCode => Object.hash(message, card, Object.hashAll(activity));
}
