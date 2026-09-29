import 'package:collection/collection.dart';

import 'package:host_app/src/modules/reference/model/term_kind.dart';

/// A tag the catalog and the records share, e.g. `headache`.
class VocabularyTerm {
  const VocabularyTerm({
    required this.id,
    required this.label,
    required this.kind,
    this.synonyms = const [],
  });

  factory VocabularyTerm.fromJson(Map<String, Object?> json) => VocabularyTerm(
    id: json['id'] as String,
    label: json['label'] as String,
    kind: TermKind.values.byName(json['kind'] as String),
    synonyms: List.unmodifiable(
      (json['synonyms'] as List<Object?>? ?? const []).cast<String>(),
    ),
  );

  final String id;

  final String label;

  final TermKind kind;

  final List<String> synonyms;

  VocabularyTerm copyWith({
    String? id,
    String? label,
    TermKind? kind,
    List<String>? synonyms,
  }) => VocabularyTerm(
    id: id ?? this.id,
    label: label ?? this.label,
    kind: kind ?? this.kind,
    synonyms: List.unmodifiable(synonyms ?? this.synonyms),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'kind': kind.name,
    'synonyms': synonyms,
  };

  @override
  bool operator ==(Object other) =>
      other is VocabularyTerm &&
      id == other.id &&
      label == other.label &&
      kind == other.kind &&
      const ListEquality<String>().equals(synonyms, other.synonyms);

  @override
  int get hashCode => Object.hash(id, label, kind, Object.hashAll(synonyms));

  @override
  String toString() => 'VocabularyTerm($id, ${kind.name})';
}
