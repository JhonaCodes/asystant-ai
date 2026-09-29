import 'package:collection/collection.dart';

/// Something people believe the plant does that is not safe to act on: shown
/// with what is actually known, never recommended.
class PlantBelief {
  const PlantBelief({
    required this.claim,
    required this.note,
    this.sources = const [],
  });

  factory PlantBelief.fromJson(Map<String, Object?> json) => PlantBelief(
    claim: json['claim'] as String,
    note: json['note'] as String,
    sources: List.unmodifiable(
      (json['sources'] as List<Object?>? ?? const []).cast<String>(),
    ),
  );

  /// What people say: "Cura el cáncer".
  final String claim;

  /// What is known: "No hay estudios en personas y puede dañar el hígado."
  final String note;

  /// Ids of the plant's sources for the belief and for what is known.
  final List<String> sources;

  PlantBelief copyWith({String? claim, String? note, List<String>? sources}) =>
      PlantBelief(
        claim: claim ?? this.claim,
        note: note ?? this.note,
        sources: List.unmodifiable(sources ?? this.sources),
      );

  Map<String, Object?> toJson() => {
    'claim': claim,
    'note': note,
    'sources': sources,
  };

  @override
  bool operator ==(Object other) =>
      other is PlantBelief &&
      claim == other.claim &&
      note == other.note &&
      const ListEquality<String>().equals(sources, other.sources);

  @override
  int get hashCode => Object.hash(claim, note, Object.hashAll(sources));

  @override
  String toString() => 'PlantBelief($claim)';
}
