import 'package:collection/collection.dart';

import 'package:host_app/src/modules/assessment/model/assessment_status.dart';
import 'package:host_app/src/modules/assessment/model/clinical_photo.dart';
import 'package:host_app/src/modules/assessment/model/goal.dart';
import 'package:host_app/src/modules/assessment/model/recommendation_snapshot.dart';
import 'package:host_app/src/modules/assessment/model/symptom.dart';
import 'package:host_app/src/shared/shared.dart';

/// One consultation: why the person came, what they feel and want, the
/// warning signs, photos, the summary and the last recommendation.
class Assessment {
  const Assessment({
    required this.id,
    required this.reason,
    required this.createdAt,
    this.status = AssessmentStatus.inProgress,
    this.symptoms = const [],
    this.goals = const [],
    this.redFlagIds = const [],
    this.photos = const [],
    this.summary = '',
    this.recommendation,
    this.updatedAt,
  });

  factory Assessment.fromJson(Map<String, Object?> json) => Assessment(
    id: json['id'] as String,
    reason: json['reason'] as String,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    status: AssessmentStatus.values.byName(
      json['status'] as String? ?? AssessmentStatus.inProgress.name,
    ),
    symptoms: _list(json['symptoms'], Symptom.fromJson),
    goals: _list(json['goals'], Goal.fromJson),
    redFlagIds: List.unmodifiable(
      (json['redFlagIds'] as List<Object?>? ?? const []).cast<String>(),
    ),
    photos: _list(json['photos'], ClinicalPhoto.fromJson),
    summary: json['summary'] as String? ?? '',
    recommendation: switch (json['recommendation']) {
      final Map<String, Object?> snapshot => RecommendationSnapshot.fromJson(
        snapshot,
      ),
      _ => null,
    },
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
  );

  final String id;

  final String reason;

  final DateTime createdAt;

  final AssessmentStatus status;

  final List<Symptom> symptoms;

  final List<Goal> goals;

  /// Warning signs the assistant recorded explicitly.
  final List<String> redFlagIds;

  final List<ClinicalPhoto> photos;

  /// The epicritic summary written by the assistant.
  final String summary;

  final RecommendationSnapshot? recommendation;

  final DateTime? updatedAt;

  /// Whether [symptom] is already recorded, by its term or its words.
  bool hasSymptom(Symptom symptom) => symptoms.any(
    (item) =>
        _same(item.tag, item.description, symptom.tag, symptom.description),
  );

  bool hasGoal(Goal goal) => goals.any(
    (item) => _same(item.tag, item.description, goal.tag, goal.description),
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

  /// Symptom and goal tags, the input of the recommendation.
  Set<String> get wantedTags => {
    for (final symptom in symptoms)
      if (symptom.tag case final String tag) tag,
    for (final goal in goals)
      if (goal.tag case final String tag) tag,
  };

  Assessment copyWith({
    String? id,
    String? reason,
    DateTime? createdAt,
    AssessmentStatus? status,
    List<Symptom>? symptoms,
    List<Goal>? goals,
    List<String>? redFlagIds,
    List<ClinicalPhoto>? photos,
    String? summary,
    RecommendationSnapshot? recommendation,
    DateTime? updatedAt,
  }) => Assessment(
    id: id ?? this.id,
    reason: reason ?? this.reason,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    symptoms: List.unmodifiable(symptoms ?? this.symptoms),
    goals: List.unmodifiable(goals ?? this.goals),
    redFlagIds: List.unmodifiable(redFlagIds ?? this.redFlagIds),
    photos: List.unmodifiable(photos ?? this.photos),
    summary: summary ?? this.summary,
    recommendation: recommendation ?? this.recommendation,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'reason': reason,
    'status': status.name,
    'symptoms': symptoms.map((item) => item.toJson()).toList(),
    'goals': goals.map((item) => item.toJson()).toList(),
    'redFlagIds': redFlagIds,
    'photos': photos.map((item) => item.toJson()).toList(),
    'summary': summary,
    'recommendation': recommendation?.toJson(),
  };

  static const _deep = DeepCollectionEquality();

  @override
  bool operator ==(Object other) =>
      other is Assessment &&
      _deep.equals(toJson(), other.toJson()) &&
      createdAt == other.createdAt &&
      updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(_deep.hash(toJson()), createdAt, updatedAt);

  @override
  String toString() => 'Assessment($id, ${status.name})';

  static List<T> _list<T>(
    Object? value,
    T Function(Map<String, Object?> json) fromJson,
  ) => List.unmodifiable(
    (value as List<Object?>? ?? const []).map(
      (item) => fromJson(item as Map<String, Object?>),
    ),
  );
}
