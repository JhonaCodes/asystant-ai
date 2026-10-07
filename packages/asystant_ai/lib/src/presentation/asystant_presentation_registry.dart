import 'package:flutter/widgets.dart';

import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/presentation/asystant_presentation.dart';

/// One registry drives tool discovery, validation and completed-card UI.
class AsystantPresentationRegistry {
  AsystantPresentationRegistry(Iterable<AsystantPresentation> presentations)
    : _presentations = List.unmodifiable(presentations) {
    for (final presentation in _presentations) {
      if (presentation.id.isEmpty || _byId.containsKey(presentation.id)) {
        throw ArgumentError.value(
          presentation.id,
          'presentation.id',
          'Presentation IDs must be nonempty and unique.',
        );
      }
      _byId[presentation.id] = presentation;
    }
  }

  final List<AsystantPresentation> _presentations;
  final Map<String, AsystantPresentation> _byId = {};

  List<AsystantTool> get tools =>
      List.unmodifiable(_presentations.map(_AsystantPresentationTool.new));

  Widget? build(
    BuildContext context,
    AssistantCard card,
    AsystantStrings strings,
    ValueChanged<String>? onOptionPressed,
  ) {
    if (card is AsystantPresentationCard) {
      return _byId[card.presentationId]?.build(
        context,
        card,
        strings,
        onOptionPressed,
      );
    }
    for (final presentation in _presentations) {
      if (presentation.matchesLegacy(card)) {
        return presentation.buildLegacy(
          context,
          card,
          strings,
          onOptionPressed,
        );
      }
    }
    return null;
  }
}

class _AsystantPresentationTool
    extends TypedAsystantTool<Map<String, Object?>> {
  const _AsystantPresentationTool(this.presentation);

  final AsystantPresentation presentation;

  @override
  bool get isAvailable => presentation.isAvailable;

  @override
  bool get requiresConfirmation => false;

  @override
  ToolDefinition get definition => ToolDefinition(
    name: presentation.id,
    description: presentation.description,
    fields: presentation.fields,
  );

  @override
  Result<Map<String, Object?>, AssistantFailure> decode(
    ToolArguments arguments,
  ) => presentation.validate(arguments);

  @override
  Future<Result<AssistantCard, AssistantFailure>> previewInput(
    Map<String, Object?> input,
  ) async => Ok(presentation.preview(input));

  @override
  Future<Result<ToolOutcome, AssistantFailure>> executeInput(
    Map<String, Object?> input,
    ToolContext context,
  ) async {
    final result = await presentation.present(input, context);
    return result.when(
      ok: (value) {
        if (!_isJsonMap(value.data)) {
          return Err(
            const AssistantFailure(
              .invalidTool,
              detail: 'Presentation data must contain JSON values only.',
            ),
          );
        }
        return Ok(
          ToolOutcome(
            modelContent: value.modelContent,
            summary: value.summary,
            endsTurn: value.endsTurn,
            card: AsystantPresentationCard(
              presentationId: presentation.id,
              data: Map.unmodifiable(value.data),
              title: value.card.title,
              body: value.card.body,
              kind: value.card.kind,
              options: value.card.options,
              chart: value.card.chart,
            ),
          ),
        );
      },
      err: Err.new,
    );
  }
}

bool _isJsonMap(Map<String, Object?> value) => value.values.every(_isJsonValue);

bool _isJsonValue(Object? value) => switch (value) {
  null || String() || bool() => true,
  final num number => number.isFinite,
  final List<Object?> items => items.every(_isJsonValue),
  final Map<Object?, Object?> items =>
    items.keys.every((key) => key is String) &&
        items.values.every(_isJsonValue),
  _ => false,
};
