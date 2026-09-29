import 'package:asystant_core/src/model/assistant_card.dart';
import 'package:asystant_core/src/model/assistant_value.dart';

/// A local execution result, with model-facing text and an optional user-facing card.
class ToolOutcome extends AssistantValue {
  const ToolOutcome({
    required this.modelContent,
    this.card,
    this.summary,
    this.data = const {},
    this.endsTurn = false,
  });

  /// What the model reads as the tool's result.
  final String modelContent;

  final AssistantCard? card;

  /// What was done, in one line for the person: "Renamed scene 2". It
  /// replaces the step's title once the tool completes; the preview title
  /// stays when null.
  final String? summary;

  /// Structured result for the host, such as ids a tool created. Kept on the
  /// step with the conversation; never sent to the model.
  final Map<String, Object?> data;

  /// Ends the person's turn after this tool: the model is not called again
  /// and the other calls of the same response are not run, so the next word
  /// belongs to the person. Use it when the tool opens a question only the
  /// person can answer, such as a product approval. [modelContent] should
  /// say that the turn stops there.
  final bool endsTurn;

  ToolOutcome copyWith({
    String? modelContent,
    AssistantCard? card,
    bool clearCard = false,
    String? summary,
    Map<String, Object?>? data,
    bool? endsTurn,
  }) => ToolOutcome(
    modelContent: modelContent ?? this.modelContent,
    card: clearCard ? null : card ?? this.card,
    summary: summary ?? this.summary,
    data: Map.unmodifiable(data ?? this.data),
    endsTurn: endsTurn ?? this.endsTurn,
  );

  factory ToolOutcome.fromJson(Map<String, Object?> json) => ToolOutcome(
    modelContent: json['model_content'] as String,
    card: switch (json['card']) {
      final Map<String, Object?> card => AssistantCard.fromJson(card),
      _ => null,
    },
    summary: json['summary'] as String?,
    data: switch (json['data']) {
      final Map<String, Object?> data => Map.unmodifiable(data),
      _ => const {},
    },
    endsTurn: json['ends_turn'] as bool? ?? false,
  );

  @override
  Map<String, Object?> toJson() => {
    'model_content': modelContent,
    'card': card?.toJson(),
    'summary': summary,
    'data': data,
    'ends_turn': endsTurn,
  };
}
