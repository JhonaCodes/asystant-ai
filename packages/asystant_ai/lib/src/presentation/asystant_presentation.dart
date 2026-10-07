import 'package:flutter/widgets.dart';

import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';

/// A read-only presentation the assistant may choose through a local tool.
///
/// The tool schema tells the model when to use it. [validate] checks its input;
/// [present] resolves trusted data before the card is stored. The resulting
/// [AsystantPresentationCard] is restored with its payload after app restarts.
abstract class AsystantPresentation {
  const AsystantPresentation();

  /// Stable tool name and card identity. Keep it unchanged across releases.
  String get id;

  /// Tell the model which information this widget presents and when to use it.
  String get description;

  List<ToolField> get fields;

  /// Rechecked before each model call and before tool execution.
  bool get isAvailable => true;

  Result<Map<String, Object?>, AssistantFailure> validate(
    ToolArguments arguments,
  );

  AssistantCard preview(Map<String, Object?> input);

  Future<Result<AsystantPresentationResult, AssistantFailure>> present(
    Map<String, Object?> input,
    ToolContext context,
  );

  Widget build(
    BuildContext context,
    AsystantPresentationCard card,
    AsystantStrings strings,
    ValueChanged<String>? onOptionPressed,
  );

  /// Recognize cards saved before this presentation was registered.
  bool matchesLegacy(AssistantCard card) => false;

  /// Render an older card if [matchesLegacy] accepted it.
  Widget? buildLegacy(
    BuildContext context,
    AssistantCard card,
    AsystantStrings strings,
    ValueChanged<String>? onOptionPressed,
  ) => null;
}

/// Validated visual data and the model-facing result of one presentation.
class AsystantPresentationResult {
  const AsystantPresentationResult({
    required this.card,
    required this.modelContent,
    this.data = const {},
    this.summary,
    this.endsTurn = false,
  });

  final AssistantCard card;

  /// JSON-compatible, trusted data used by the registered widget.
  final Map<String, Object?> data;

  final String modelContent;

  final String? summary;

  /// Stop after a question that waits for the person to choose.
  final bool endsTurn;
}

/// A durable card that identifies its presentation without changing core.
class AsystantPresentationCard extends AssistantCard {
  const AsystantPresentationCard({
    required this.presentationId,
    required this.data,
    required super.title,
    super.body,
    super.kind,
    super.options,
    super.chart,
  });

  final String presentationId;

  final Map<String, Object?> data;

  factory AsystantPresentationCard.fromJson(Map<String, Object?> json) {
    final base = AssistantCard.fromJson(json);
    return AsystantPresentationCard(
      presentationId: json['presentation_id'] as String,
      data: (json['presentation_data'] as Map).cast<String, Object?>(),
      title: base.title,
      body: base.body,
      kind: base.kind,
      options: base.options,
      chart: base.chart,
    );
  }

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'presentation_id': presentationId,
    'presentation_data': data,
  };
}
