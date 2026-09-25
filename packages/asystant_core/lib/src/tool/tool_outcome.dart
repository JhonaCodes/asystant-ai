import 'package:asystant_core/src/model/assistant_card.dart';
import 'package:asystant_core/src/model/assistant_value.dart';

/// A local execution result, with model-facing text and an optional user-facing card.
class ToolOutcome extends AssistantValue {
  const ToolOutcome({required this.modelContent, this.card});

  final String modelContent;

  final AssistantCard? card;

  ToolOutcome copyWith({
    String? modelContent,
    AssistantCard? card,
    bool clearCard = false,
  }) => ToolOutcome(
    modelContent: modelContent ?? this.modelContent,
    card: clearCard ? null : card ?? this.card,
  );

  factory ToolOutcome.fromJson(Map<String, Object?> json) => ToolOutcome(
    modelContent: json['model_content'] as String,
    card: switch (json['card']) {
      final Map<String, Object?> card => AssistantCard.fromJson(card),
      _ => null,
    },
  );

  @override
  Map<String, Object?> toJson() => {
    'model_content': modelContent,
    'card': card?.toJson(),
  };
}
