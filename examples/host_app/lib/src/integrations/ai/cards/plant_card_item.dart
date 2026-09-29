part of '../ai.dart';

/// One plant as the chat shows it: only what its card needs.
@immutable
final class _PlantCardItem {
  const _PlantCardItem({
    required this.id,
    required this.name,
    this.scientificName = '',
    this.photoRef = '',
    this.uses = '',
    this.addedByPerson = false,
  });

  factory _PlantCardItem.of(Plant plant) => _PlantCardItem(
    id: plant.id,
    name: plant.commonName,
    scientificName: plant.scientificName,
    photoRef: plant.mainPhoto?.ref ?? '',
    uses: plant.usesLine,
    addedByPerson: !plant.isSeed,
  );

  final String id;

  final String name;

  final String scientificName;

  /// A stored file reference: `asset://`, `local://` or `https://`.
  final String photoRef;

  /// What it is used for, in one line: "Digestión · Tos".
  final String uses;

  final bool addedByPerson;

  /// "Manzanilla (Matricaria chamomilla). Usos: Digestión · Tos."
  String get modelLine => [
    '- $id: $name',
    if (scientificName.isNotEmpty) ' ($scientificName)',
    if (uses.isNotEmpty) '. Usos: $uses',
    if (addedByPerson) '. Agregada por la persona, sin datos verificados',
  ].join();

  _PlantCardItem copyWith({
    String? id,
    String? name,
    String? scientificName,
    String? photoRef,
    String? uses,
    bool? addedByPerson,
  }) => _PlantCardItem(
    id: id ?? this.id,
    name: name ?? this.name,
    scientificName: scientificName ?? this.scientificName,
    photoRef: photoRef ?? this.photoRef,
    uses: uses ?? this.uses,
    addedByPerson: addedByPerson ?? this.addedByPerson,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'scientificName': scientificName,
    'photoRef': photoRef,
    'uses': uses,
    'addedByPerson': addedByPerson,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PlantCardItem &&
          id == other.id &&
          name == other.name &&
          scientificName == other.scientificName &&
          photoRef == other.photoRef &&
          uses == other.uses &&
          addedByPerson == other.addedByPerson;

  @override
  int get hashCode =>
      Object.hash(id, name, scientificName, photoRef, uses, addedByPerson);

  @override
  String toString() => '_PlantCardItem($id, $name)';
}
