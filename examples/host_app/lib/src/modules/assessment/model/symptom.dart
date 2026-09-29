import 'package:collection/collection.dart';

/// Something the person feels, as the assistant recorded it.
class Symptom {
  const Symptom({
    required this.id,
    required this.description,
    this.tag,
    this.onset = '',
    this.durationDays,
    this.intensity,
    this.location = '',
    this.aggravating = const [],
    this.relieving = const [],
  });

  factory Symptom.fromJson(Map<String, Object?> json) => Symptom(
    id: json['id'] as String,
    description: json['description'] as String,
    tag: json['tag'] as String?,
    onset: json['onset'] as String? ?? '',
    durationDays: json['durationDays'] as int?,
    intensity: json['intensity'] as int?,
    location: json['location'] as String? ?? '',
    aggravating: _strings(json['aggravating']),
    relieving: _strings(json['relieving']),
  );

  final String id;

  final String description;

  /// The vocabulary term, e.g. `headache`.
  final String? tag;

  /// When it started, in the person's words.
  final String onset;

  final int? durationDays;

  /// From 0 (none) to 10 (worst).
  final int? intensity;

  final String location;

  final List<String> aggravating;

  final List<String> relieving;

  Symptom copyWith({
    String? id,
    String? description,
    String? tag,
    String? onset,
    int? durationDays,
    int? intensity,
    String? location,
    List<String>? aggravating,
    List<String>? relieving,
  }) => Symptom(
    id: id ?? this.id,
    description: description ?? this.description,
    tag: tag ?? this.tag,
    onset: onset ?? this.onset,
    durationDays: durationDays ?? this.durationDays,
    intensity: intensity ?? this.intensity,
    location: location ?? this.location,
    aggravating: List.unmodifiable(aggravating ?? this.aggravating),
    relieving: List.unmodifiable(relieving ?? this.relieving),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'description': description,
    'tag': tag,
    'onset': onset,
    'durationDays': durationDays,
    'intensity': intensity,
    'location': location,
    'aggravating': aggravating,
    'relieving': relieving,
  };

  @override
  bool operator ==(Object other) =>
      other is Symptom &&
      const DeepCollectionEquality().equals(toJson(), other.toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());

  @override
  String toString() => 'Symptom($id, $tag)';

  static List<String> _strings(Object? value) =>
      List.unmodifiable((value as List<Object?>? ?? const []).cast<String>());
}
