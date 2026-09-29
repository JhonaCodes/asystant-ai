part of '../ai.dart';

/// A gen-ui card that carries a recommendation; the chat draws the plants
/// with how to take them, as the recommendation screen does.
final class _RecommendationCard extends AssistantCard {
  const _RecommendationCard({
    required super.title,
    required this.consultationId,
    required this.snapshot,
    super.body,
    super.kind = AssistantCardKind.entity,
    super.options,
    super.chart,
  });

  /// The consultation that keeps it, so the person finds it in the app.
  final String consultationId;

  final RecommendationSnapshot snapshot;

  /// What the model reads to explain the result, never more than this.
  String get modelSummary => [
    'Consulta: $consultationId.',
    switch (snapshot.status) {
      RecommendationStatus.recommended =>
        'Plantas del catálogo para esto, en orden:',
      RecommendationStatus.seeDoctor =>
        'Hay señales de alarma: pide a la persona que busque atención médica '
            'ya y no sugieras plantas. Señales: '
            '${snapshot.redFlags.map((hit) => hit.summary).join('; ')}.',
      RecommendationStatus.needsInformation =>
        'Faltan datos para recomendar con seguridad: '
            '${snapshot.missing.map((item) => item.label).join(', ')}. '
            'Pregúntalos, guárdalos con save_profile y vuelve a llamar esta '
            'herramienta con consultation_id $consultationId.',
      RecommendationStatus.allExcluded =>
        'Hay plantas para esto, pero ninguna es segura para esta persona.',
      RecommendationStatus.noMatch =>
        'El catálogo no tiene plantas con respaldo para esto. Dilo con '
            'claridad y no sugieras otras.',
    },
    ...snapshot.suggestions.map(_suggestionLine),
    if (snapshot.excluded.isNotEmpty)
      'Descartadas por seguridad: '
          '${snapshot.excluded.map((plant) => plant.summary).join('; ')}.',
    if (snapshot.uncovered.isNotEmpty)
      'Sin respaldo en el catálogo: ${snapshot.uncovered.join(', ')}.',
    'La tarjeta ya le muestra a la persona cada preparación con dibujos, '
        'pasos, cantidades y precauciones. Responde en una o dos frases '
        'sencillas: qué planta y de qué forma usarla (por ejemplo, "un té de '
        'manzanilla"). No repitas los pasos ni las cantidades y no agregues '
        'plantas, cantidades ni usos que no estén aquí.',
  ].join('\n');

  static String _suggestionLine(PlantSuggestion plant) => [
    '- ${plant.commonName}',
    if (plant.popularOnly)
      ' [solo uso popular, no comprobado: dilo así a la persona]',
    if (plant.scientificName.isNotEmpty) ' (${plant.scientificName})',
    '. Ayuda con: ${plant.matchedLine}.',
    for (final preparation in plant.preparations) _preparationLine(preparation),
    if (plant.cautions.isNotEmpty)
      ' Precauciones: ${plant.cautions.join('; ')}.',
  ].join();

  static String _preparationLine(Preparation preparation) => [
    ' Forma: ${preparation.displayTitle}',
    if (preparation.steps.isNotEmpty)
      ' (${preparation.steps.map((step) => step.text).join(' ')})',
    if (preparation.dose.isNotEmpty) ' Cantidad: ${preparation.dose}',
    if (preparation.maxDays case final days?) ' Máximo $days días seguidos.',
    if (preparation.warnings.isNotEmpty)
      ' Cuidado: ${preparation.warnings.join(' ')}',
  ].join();

  @override
  _RecommendationCard copyWith({
    String? title,
    String? body,
    AssistantCardKind? kind,
    List<String>? options,
    AssistantChart? chart,
    bool clearChart = false,
    String? consultationId,
    RecommendationSnapshot? snapshot,
  }) => _RecommendationCard(
    title: title ?? this.title,
    body: body ?? this.body,
    kind: kind ?? this.kind,
    options: List.unmodifiable(options ?? this.options),
    chart: clearChart ? null : chart ?? this.chart,
    consultationId: consultationId ?? this.consultationId,
    snapshot: snapshot ?? this.snapshot,
  );

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'consultationId': consultationId,
    'snapshot': snapshot.toJson(),
  };
}
