import 'package:collection/collection.dart';

/// A warning sign that needs a doctor instead of a plant.
///
/// It fires when a symptom carries one of [triggerTags] (or any symptom
/// when [anySymptom]), subject to the optional intensity, duration and age
/// limits.
class RedFlagRule {
  const RedFlagRule({
    required this.id,
    required this.label,
    required this.advice,
    this.triggerTags = const [],
    this.minIntensity,
    this.minDurationDays,
    this.anySymptom = false,
    this.maxAgeYears,
  });

  factory RedFlagRule.fromJson(Map<String, Object?> json) => RedFlagRule(
    id: json['id'] as String,
    label: json['label'] as String,
    advice: json['advice'] as String,
    triggerTags: List.unmodifiable(
      (json['triggerTags'] as List<Object?>? ?? const []).cast<String>(),
    ),
    minIntensity: json['minIntensity'] as int?,
    minDurationDays: json['minDurationDays'] as int?,
    anySymptom: json['anySymptom'] as bool? ?? false,
    maxAgeYears: json['maxAgeYears'] as int?,
  );

  final String id;

  final String label;

  final String advice;

  final List<String> triggerTags;

  final int? minIntensity;

  final int? minDurationDays;

  final bool anySymptom;

  /// Fires only for people this age or younger.
  final int? maxAgeYears;

  RedFlagRule copyWith({
    String? id,
    String? label,
    String? advice,
    List<String>? triggerTags,
    int? minIntensity,
    int? minDurationDays,
    bool? anySymptom,
    int? maxAgeYears,
  }) => RedFlagRule(
    id: id ?? this.id,
    label: label ?? this.label,
    advice: advice ?? this.advice,
    triggerTags: List.unmodifiable(triggerTags ?? this.triggerTags),
    minIntensity: minIntensity ?? this.minIntensity,
    minDurationDays: minDurationDays ?? this.minDurationDays,
    anySymptom: anySymptom ?? this.anySymptom,
    maxAgeYears: maxAgeYears ?? this.maxAgeYears,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'advice': advice,
    'triggerTags': triggerTags,
    'minIntensity': minIntensity,
    'minDurationDays': minDurationDays,
    'anySymptom': anySymptom,
    'maxAgeYears': maxAgeYears,
  };

  @override
  bool operator ==(Object other) =>
      other is RedFlagRule &&
      id == other.id &&
      label == other.label &&
      advice == other.advice &&
      const ListEquality<String>().equals(triggerTags, other.triggerTags) &&
      minIntensity == other.minIntensity &&
      minDurationDays == other.minDurationDays &&
      anySymptom == other.anySymptom &&
      maxAgeYears == other.maxAgeYears;

  @override
  int get hashCode => Object.hash(
    id,
    label,
    advice,
    Object.hashAll(triggerTags),
    minIntensity,
    minDurationDays,
    anySymptom,
    maxAgeYears,
  );

  @override
  String toString() => 'RedFlagRule($id)';
}
