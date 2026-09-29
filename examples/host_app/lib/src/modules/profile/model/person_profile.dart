import 'package:collection/collection.dart';

import 'package:host_app/src/modules/profile/model/biological_sex.dart';
import 'package:host_app/src/modules/profile/model/habits.dart';
import 'package:host_app/src/modules/profile/model/profile_entries.dart';
import 'package:host_app/src/shared/shared.dart';

/// The person's health history, as the assistant recorded it.
class PersonProfile {
  const PersonProfile({
    this.displayName = '',
    this.birthDate,
    this.sex = BiologicalSex.unspecified,
    this.weightKg,
    this.heightCm,
    this.isPregnant,
    this.isLactating,
    this.conditions = const [],
    this.medications = const [],
    this.allergies = const [],
    this.habits = const Habits(),
    this.familyHistory = const [],
    this.updatedAt,
  });

  static const empty = PersonProfile();

  factory PersonProfile.fromJson(Map<String, Object?> json) => PersonProfile(
    displayName: json['displayName'] as String? ?? '',
    birthDate: DateTime.tryParse(json['birthDate'] as String? ?? ''),
    sex: BiologicalSex.values.byName(
      json['sex'] as String? ?? BiologicalSex.unspecified.name,
    ),
    weightKg: (json['weightKg'] as num?)?.toDouble(),
    heightCm: (json['heightCm'] as num?)?.toDouble(),
    isPregnant: json['isPregnant'] as bool?,
    isLactating: json['isLactating'] as bool?,
    conditions: _list(json['conditions'], HealthCondition.fromJson),
    medications: _list(json['medications'], Medication.fromJson),
    allergies: _list(json['allergies'], Allergy.fromJson),
    habits: switch (json['habits']) {
      final Map<String, Object?> habits => Habits.fromJson(habits),
      _ => const Habits(),
    },
    familyHistory: List.unmodifiable(
      (json['familyHistory'] as List<Object?>? ?? const []).cast<String>(),
    ),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
  );

  final String displayName;

  final DateTime? birthDate;

  final BiologicalSex sex;

  final double? weightKg;

  final double? heightCm;

  /// Null until the assistant asked.
  final bool? isPregnant;

  final bool? isLactating;

  final List<HealthCondition> conditions;

  final List<Medication> medications;

  final List<Allergy> allergies;

  final Habits habits;

  final List<String> familyHistory;

  final DateTime? updatedAt;

  /// Whether the assistant has recorded anything yet.
  bool get hasData => this != empty && updatedAt != null;

  /// Whole years at [now], or null without a birth date.
  int? ageAt(DateTime now) {
    final birth = birthDate;
    if (birth == null) {
      return null;
    }
    final hadBirthday =
        now.month > birth.month ||
        (now.month == birth.month && now.day >= birth.day);
    return now.year - birth.year - (hadBirthday ? 0 : 1);
  }

  /// The profile with what the person just said, in a single change.
  ///
  /// A condition or allergy already recorded, by its term or its words, is
  /// not added again; an age that is still right keeps the stored birth
  /// date, so saying it twice changes nothing.
  PersonProfile withFacts({
    required DateTime today,
    int? age,
    BiologicalSex? sex,
    bool? isPregnant,
    bool? isLactating,
    List<HealthCondition> conditions = const [],
    List<Allergy> allergies = const [],
  }) => copyWith(
    birthDate: switch (age) {
      final years? when ageAt(today) != years => DateTime(
        today.year - years,
        today.month,
        today.day,
      ),
      _ => null,
    },
    sex: sex,
    isPregnant: isPregnant,
    isLactating: isLactating,
    conditions: _merged(this.conditions, conditions, _sameCondition),
    allergies: _merged(this.allergies, allergies, _sameAllergy),
  );

  bool hasMedication(Medication medication) => medications.any(
    (item) => item.name.searchKey == medication.name.searchKey,
  );

  static bool _sameCondition(HealthCondition a, HealthCondition b) =>
      _same(a.tag, a.description, b.tag, b.description);

  static bool _sameAllergy(Allergy a, Allergy b) =>
      _same(a.tag, a.description, b.tag, b.description);

  /// [kept] plus each of [added] that is not already there.
  static List<T> _merged<T>(
    List<T> kept,
    List<T> added,
    bool Function(T a, T b) same,
  ) => added.fold(
    kept,
    (list, item) =>
        list.any((existing) => same(existing, item)) ? list : [...list, item],
  );

  static bool _same(
    String? tag,
    String words,
    String? otherTag,
    String other,
  ) => switch ((tag, otherTag)) {
    (final String a, final String b) => a == b,
    _ => words.searchKey == other.searchKey,
  };

  Set<String> get conditionTags => {
    for (final condition in conditions)
      if (condition.tag case final String tag) tag,
  };

  Set<String> get medicationClasses => {
    for (final medication in medications) ...medication.classTags,
  };

  Set<String> get allergyTags => {
    for (final allergy in allergies)
      if (allergy.tag case final String tag) tag,
  };

  PersonProfile copyWith({
    String? displayName,
    DateTime? birthDate,
    BiologicalSex? sex,
    double? weightKg,
    double? heightCm,
    bool? isPregnant,
    bool? isLactating,
    List<HealthCondition>? conditions,
    List<Medication>? medications,
    List<Allergy>? allergies,
    Habits? habits,
    List<String>? familyHistory,
    DateTime? updatedAt,
  }) => PersonProfile(
    displayName: displayName ?? this.displayName,
    birthDate: birthDate ?? this.birthDate,
    sex: sex ?? this.sex,
    weightKg: weightKg ?? this.weightKg,
    heightCm: heightCm ?? this.heightCm,
    isPregnant: isPregnant ?? this.isPregnant,
    isLactating: isLactating ?? this.isLactating,
    conditions: List.unmodifiable(conditions ?? this.conditions),
    medications: List.unmodifiable(medications ?? this.medications),
    allergies: List.unmodifiable(allergies ?? this.allergies),
    habits: habits ?? this.habits,
    familyHistory: List.unmodifiable(familyHistory ?? this.familyHistory),
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toJson() => {
    'displayName': displayName,
    'birthDate': birthDate?.toIso8601String(),
    'sex': sex.name,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'isPregnant': isPregnant,
    'isLactating': isLactating,
    'conditions': conditions.map((item) => item.toJson()).toList(),
    'medications': medications.map((item) => item.toJson()).toList(),
    'allergies': allergies.map((item) => item.toJson()).toList(),
    'habits': habits.toJson(),
    'familyHistory': familyHistory,
  };

  static const _deep = DeepCollectionEquality();

  @override
  bool operator ==(Object other) =>
      other is PersonProfile &&
      _deep.equals(toJson(), other.toJson()) &&
      updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(_deep.hash(toJson()), updatedAt);

  @override
  String toString() => 'PersonProfile(${hasData ? 'recorded' : 'empty'})';

  static List<T> _list<T>(
    Object? value,
    T Function(Map<String, Object?> json) fromJson,
  ) => List.unmodifiable(
    (value as List<Object?>? ?? const []).map(
      (item) => fromJson(item as Map<String, Object?>),
    ),
  );
}
