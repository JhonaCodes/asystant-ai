import 'package:collection/collection.dart';

import 'package:host_app/src/modules/plant/model/plant.dart';
import 'package:host_app/src/modules/plant/model/plant_enums.dart';
import 'package:host_app/src/shared/shared.dart';

/// Which plants the list shows.
enum PlantOriginFilter { all, seed, person }

/// The catalog on screen: every plant, the search and the selection.
class PlantCatalog {
  const PlantCatalog({
    this.plants = const [],
    this.query = '',
    this.filter = PlantOriginFilter.all,
    this.selectedId,
  });

  /// Every plant, sorted by common name.
  final List<Plant> plants;

  final String query;

  final PlantOriginFilter filter;

  final String? selectedId;

  Plant? get selected =>
      plants.firstWhereOrNull((plant) => plant.id == selectedId);

  Plant? byId(String id) => plants.firstWhereOrNull((plant) => plant.id == id);

  /// The plants that match the filter and the search, accent-insensitive.
  List<Plant> get visible {
    final key = query.searchKey;
    return plants.where((plant) {
      final origin = switch (filter) {
        PlantOriginFilter.all => true,
        PlantOriginFilter.seed => plant.origin == PlantOrigin.seed,
        PlantOriginFilter.person => plant.origin == PlantOrigin.person,
      };
      return origin &&
          (key.isEmpty ||
              plant.names.any((name) => name.searchKey.contains(key)));
    }).toList();
  }

  int get personCount =>
      plants.where((plant) => plant.origin == PlantOrigin.person).length;

  PlantCatalog copyWith({
    List<Plant>? plants,
    String? query,
    PlantOriginFilter? filter,
    String? selectedId,
    bool clearSelection = false,
  }) => PlantCatalog(
    plants: List.unmodifiable(plants ?? this.plants),
    query: query ?? this.query,
    filter: filter ?? this.filter,
    selectedId: clearSelection ? null : selectedId ?? this.selectedId,
  );

  Map<String, Object?> toJson() => {
    'plants': plants.map((plant) => plant.toJson()).toList(),
    'query': query,
    'filter': filter.name,
    'selectedId': selectedId,
  };

  factory PlantCatalog.fromJson(Map<String, Object?> json) => PlantCatalog(
    plants: List.unmodifiable(
      (json['plants'] as List<Object?>? ?? const []).map(
        (plant) => Plant.fromJson(plant as Map<String, Object?>),
      ),
    ),
    query: json['query'] as String? ?? '',
    filter: PlantOriginFilter.values.byName(
      json['filter'] as String? ?? PlantOriginFilter.all.name,
    ),
    selectedId: json['selectedId'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      other is PlantCatalog &&
      const ListEquality<Plant>().equals(plants, other.plants) &&
      query == other.query &&
      filter == other.filter &&
      selectedId == other.selectedId;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(plants), query, filter, selectedId);

  @override
  String toString() => 'PlantCatalog(${plants.length} plants)';
}
