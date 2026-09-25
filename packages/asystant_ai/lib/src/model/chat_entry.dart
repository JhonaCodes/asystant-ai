import 'package:asystant_core/asystant_core.dart';

/// Ephemeral display order, separate from the provider's tool-call transcript.
class ChatEntry {
  const ChatEntry({this.message, this.card});
  final AssistantMessage? message;
  final AssistantCard? card;
  ChatEntry copyWith({AssistantMessage? message, AssistantCard? card}) =>
      ChatEntry(message: message ?? this.message, card: card ?? this.card);
  @override
  bool operator ==(Object other) =>
      other is ChatEntry && message == other.message && card == other.card;
  @override
  int get hashCode => Object.hash(message, card);
}
