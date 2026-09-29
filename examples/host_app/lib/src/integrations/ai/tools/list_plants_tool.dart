part of '../ai.dart';

/// Shows the plant catalog as cards in the chat, optionally by name.
///
/// Read-only, so it runs without asking the person first.
final class _ListPlantsTool extends TypedAsystantTool<String> {
  const _ListPlantsTool();

  static const _name = 'name';

  @override
  bool get requiresConfirmation => false;

  @override
  ToolDefinition get definition => const ToolDefinition(
    name: 'list_plants',
    description:
        'Muestra a la persona, en tarjetas dentro del chat, las plantas del '
        'catálogo de la app con su foto, su nombre y para qué se usan. Úsala '
        'cuando quiera ver las plantas disponibles o buscar una por su '
        'nombre. No recomienda plantas ni cambia datos.',
    fields: [
      ToolField(
        name: _name,
        description:
            'Parte del nombre común o científico para buscar. Omítelo para '
            'mostrar todas las plantas.',
        kind: .string,
        isRequired: false,
      ),
    ],
  );

  /// The searched name, trimmed; empty for the whole catalog.
  @override
  Result<String, AssistantFailure> decode(ToolArguments arguments) =>
      switch (arguments.toJson()[_name]) {
        null => Ok(''),
        final String name => Ok(name.trim()),
        _ => Err(
          const AssistantFailure(.invalidTool, detail: 'name must be text'),
        ),
      };

  @override
  Future<Result<AssistantCard, AssistantFailure>> previewInput(
    String query,
  ) async =>
      Ok(const AssistantCard(title: AssistantToolStrings.readingCatalog));

  @override
  Future<Result<ToolOutcome, AssistantFailure>> executeInput(
    String query,
    ToolContext context,
  ) async {
    if (await PlantService.notifier.loaded() == null) {
      Log.w('list_plants: the plant catalog is not available');
      return Err(const AssistantFailure(.unavailable, detail: 'Plant catalog'));
    }
    final plants = PlantService.notifier.findByName(query);
    if (plants.isEmpty) {
      return Ok(
        ToolOutcome(
          modelContent:
              'No hay plantas con el nombre «$query» en el catálogo. Díselo '
              'a la persona y ofrécele ver todas las plantas.',
        ),
      );
    }
    final card = _PlantListCard.of(plants, query: query);
    return Ok(ToolOutcome(modelContent: card.modelSummary, card: card));
  }
}
