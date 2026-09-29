import 'package:collection/collection.dart';

/// A health condition the person has, e.g. `hypertension`.
class HealthCondition {
  const HealthCondition({
    required this.id,
    required this.description,
    this.tag,
    this.since = '',
  });

  factory HealthCondition.fromJson(Map<String, Object?> json) =>
      HealthCondition(
        id: json['id'] as String,
        description: json['description'] as String,
        tag: json['tag'] as String?,
        since: json['since'] as String? ?? '',
      );

  final String id;

  final String description;

  /// The vocabulary term, when the condition maps to one.
  final String? tag;

  final String since;

  /// One line for lists: "Hipertensión · desde 2020".
  String get summary =>
      [description, since].where((part) => part.isNotEmpty).join(' · ');

  HealthCondition copyWith({
    String? id,
    String? description,
    String? tag,
    String? since,
  }) => HealthCondition(
    id: id ?? this.id,
    description: description ?? this.description,
    tag: tag ?? this.tag,
    since: since ?? this.since,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'description': description,
    'tag': tag,
    'since': since,
  };

  @override
  bool operator ==(Object other) =>
      other is HealthCondition &&
      id == other.id &&
      description == other.description &&
      tag == other.tag &&
      since == other.since;

  @override
  int get hashCode => Object.hash(id, description, tag, since);

  @override
  String toString() => 'HealthCondition($id, $tag)';
}

/// A medicine the person takes, with its classes (e.g. `anticoagulant`).
class Medication {
  const Medication({
    required this.id,
    required this.name,
    this.classTags = const [],
    this.dose = '',
    this.frequency = '',
  });

  factory Medication.fromJson(Map<String, Object?> json) => Medication(
    id: json['id'] as String,
    name: json['name'] as String,
    classTags: List.unmodifiable(
      (json['classTags'] as List<Object?>? ?? const []).cast<String>(),
    ),
    dose: json['dose'] as String? ?? '',
    frequency: json['frequency'] as String? ?? '',
  );

  final String id;

  final String name;

  final List<String> classTags;

  final String dose;

  final String frequency;

  String get summary =>
      [name, dose, frequency].where((part) => part.isNotEmpty).join(' · ');

  Medication copyWith({
    String? id,
    String? name,
    List<String>? classTags,
    String? dose,
    String? frequency,
  }) => Medication(
    id: id ?? this.id,
    name: name ?? this.name,
    classTags: List.unmodifiable(classTags ?? this.classTags),
    dose: dose ?? this.dose,
    frequency: frequency ?? this.frequency,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'classTags': classTags,
    'dose': dose,
    'frequency': frequency,
  };

  @override
  bool operator ==(Object other) =>
      other is Medication &&
      id == other.id &&
      name == other.name &&
      const ListEquality<String>().equals(classTags, other.classTags) &&
      dose == other.dose &&
      frequency == other.frequency;

  @override
  int get hashCode =>
      Object.hash(id, name, Object.hashAll(classTags), dose, frequency);

  @override
  String toString() => 'Medication($id, $classTags)';
}

/// An allergy, mapped to an allergen group when possible (e.g. `asteraceae`).
class Allergy {
  const Allergy({
    required this.id,
    required this.description,
    this.tag,
    this.reaction = '',
  });

  factory Allergy.fromJson(Map<String, Object?> json) => Allergy(
    id: json['id'] as String,
    description: json['description'] as String,
    tag: json['tag'] as String?,
    reaction: json['reaction'] as String? ?? '',
  );

  final String id;

  final String description;

  final String? tag;

  final String reaction;

  String get summary =>
      [description, reaction].where((part) => part.isNotEmpty).join(' · ');

  Allergy copyWith({
    String? id,
    String? description,
    String? tag,
    String? reaction,
  }) => Allergy(
    id: id ?? this.id,
    description: description ?? this.description,
    tag: tag ?? this.tag,
    reaction: reaction ?? this.reaction,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'description': description,
    'tag': tag,
    'reaction': reaction,
  };

  @override
  bool operator ==(Object other) =>
      other is Allergy &&
      id == other.id &&
      description == other.description &&
      tag == other.tag &&
      reaction == other.reaction;

  @override
  int get hashCode => Object.hash(id, description, tag, reaction);

  @override
  String toString() => 'Allergy($id, $tag)';
}
