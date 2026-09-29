import 'package:collection/collection.dart';

import 'package:host_app/src/modules/plant/model/plant_enums.dart';

/// What a plant is used for: a symptom or goal tag and its evidence.
class PlantIndication {
  const PlantIndication({
    required this.tag,
    required this.label,
    required this.evidence,
    this.note = '',
    this.sources = const [],
  });

  factory PlantIndication.fromJson(Map<String, Object?> json) =>
      PlantIndication(
        tag: json['tag'] as String,
        label: json['label'] as String,
        evidence: EvidenceLevel.values.byName(json['evidence'] as String),
        note: json['note'] as String? ?? '',
        sources: List.unmodifiable(
          (json['sources'] as List<Object?>? ?? const []).cast<String>(),
        ),
      );

  final String tag;

  final String label;

  final EvidenceLevel evidence;

  final String note;

  /// Ids of the plant's sources that back this use.
  final List<String> sources;

  /// Whether only popular belief backs it.
  bool get isPopular => evidence == EvidenceLevel.popular;

  PlantIndication copyWith({
    String? tag,
    String? label,
    EvidenceLevel? evidence,
    String? note,
    List<String>? sources,
  }) => PlantIndication(
    tag: tag ?? this.tag,
    label: label ?? this.label,
    evidence: evidence ?? this.evidence,
    note: note ?? this.note,
    sources: List.unmodifiable(sources ?? this.sources),
  );

  Map<String, Object?> toJson() => {
    'tag': tag,
    'label': label,
    'evidence': evidence.name,
    'note': note,
    'sources': sources,
  };

  @override
  bool operator ==(Object other) =>
      other is PlantIndication &&
      tag == other.tag &&
      label == other.label &&
      evidence == other.evidence &&
      note == other.note &&
      const ListEquality<String>().equals(sources, other.sources);

  @override
  int get hashCode =>
      Object.hash(tag, label, evidence, note, Object.hashAll(sources));

  @override
  String toString() => 'PlantIndication($tag, ${evidence.name})';
}
