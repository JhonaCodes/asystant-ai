part of '../ai.dart';

/// A gen-ui card that carries plants; the chat draws them as a gallery.
final class _PlantListCard extends AssistantCard {
  const _PlantListCard({
    required super.title,
    required this.plants,
    this.query = '',
    super.body,
    super.kind = AssistantCardKind.entity,
    super.options,
    super.chart,
  });

  factory _PlantListCard.of(List<Plant> plants, {required String query}) =>
      _PlantListCard(
        title: AssistantToolStrings.plantsFound(plants.length, query),
        plants: List.unmodifiable([
          for (final plant in plants) _PlantCardItem.of(plant),
        ]),
        query: query,
      );

  static const _minTileWidth = 150.0;

  /// Plants per page: three rows of two on a phone, two of three when wide.
  static const pageSize = 6;

  final List<_PlantCardItem> plants;

  /// The name the person searched for; empty when showing every plant.
  final String query;

  /// Two tiles per row on a phone, three when the chat is wide.
  static int columnsFor(double width) =>
      (width / _minTileWidth).floor().clamp(2, 3);

  int get pageCount => (plants.length / pageSize).ceil();

  bool get isPaged => pageCount > 1;

  bool hasPrevious(int page) => page > 0;

  bool hasNext(int page) => page < pageCount - 1;

  /// "7–12 de 13" for the second page.
  String rangeOf(int page) => AssistantToolStrings.range(
    page * pageSize + 1,
    page * pageSize + _pageOf(page).length,
    plants.length,
  );

  /// The rows of [page], the last one padded with empty cells.
  List<List<_PlantCardItem?>> rows(int columns, int page) => [
    for (final row in _pageOf(page).slices(columns))
      [...row, ...List<_PlantCardItem?>.filled(columns - row.length, null)],
  ];

  List<_PlantCardItem> _pageOf(int page) =>
      plants.skip(page * pageSize).take(pageSize).toList();

  /// What the model reads: the plants shown, so it can talk about them.
  String get modelSummary => [
    'Se mostraron ${plants.length} plantas en tarjetas dentro del chat. '
        'No repitas la lista: comenta en una o dos frases. Mostrar el '
        'catálogo no es recomendar.',
    ...plants.map((plant) => plant.modelLine),
  ].join('\n');

  @override
  _PlantListCard copyWith({
    String? title,
    String? body,
    AssistantCardKind? kind,
    List<String>? options,
    AssistantChart? chart,
    bool clearChart = false,
    List<_PlantCardItem>? plants,
    String? query,
  }) => _PlantListCard(
    title: title ?? this.title,
    body: body ?? this.body,
    kind: kind ?? this.kind,
    options: List.unmodifiable(options ?? this.options),
    chart: clearChart ? null : chart ?? this.chart,
    plants: List.unmodifiable(plants ?? this.plants),
    query: query ?? this.query,
  );

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'query': query,
    'plants': [for (final plant in plants) plant.toJson()],
  };
}
