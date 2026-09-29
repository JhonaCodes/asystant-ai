import 'package:collection/collection.dart';

import 'package:host_app/src/modules/assessment/model/assessment.dart';
import 'package:host_app/src/modules/plant/model/plant.dart';
import 'package:host_app/src/modules/profile/model/person_profile.dart';
import 'package:host_app/src/modules/reference/model/reference_data.dart';

/// Everything the engine reads for one recommendation.
///
/// Built right before evaluating; it is not stored, but serializes like any
/// model for debugging and tests.
class RecommendationInput {
  const RecommendationInput({
    required this.profile,
    required this.assessment,
    required this.plants,
    required this.reference,
    required this.now,
  });

  final PersonProfile profile;

  final Assessment assessment;

  final List<Plant> plants;

  final ReferenceData reference;

  /// Passed in so the same input always gives the same result.
  final DateTime now;

  factory RecommendationInput.fromJson(
    Map<String, Object?> json,
  ) => RecommendationInput(
    profile: PersonProfile.fromJson(json['profile'] as Map<String, Object?>),
    assessment: Assessment.fromJson(json['assessment'] as Map<String, Object?>),
    plants: List.unmodifiable(
      (json['plants'] as List<Object?>).map(
        (plant) => Plant.fromJson(plant as Map<String, Object?>),
      ),
    ),
    reference: ReferenceData.fromJson(
      json['reference'] as Map<String, Object?>,
    ),
    now: DateTime.parse(json['now'] as String),
  );

  int? get age => profile.ageAt(now);

  Map<String, Object?> toJson() => {
    'profile': profile.toJson(),
    'assessment': assessment.toJson(),
    'plants': plants.map((plant) => plant.toJson()).toList(),
    'reference': reference.toJson(),
    'now': now.toUtc().toIso8601String(),
  };

  RecommendationInput copyWith({
    PersonProfile? profile,
    Assessment? assessment,
    List<Plant>? plants,
    ReferenceData? reference,
    DateTime? now,
  }) => RecommendationInput(
    profile: profile ?? this.profile,
    assessment: assessment ?? this.assessment,
    plants: plants ?? this.plants,
    reference: reference ?? this.reference,
    now: now ?? this.now,
  );

  @override
  bool operator ==(Object other) =>
      other is RecommendationInput &&
      profile == other.profile &&
      assessment == other.assessment &&
      const ListEquality<Plant>().equals(plants, other.plants) &&
      reference == other.reference &&
      now == other.now;

  @override
  int get hashCode =>
      Object.hash(profile, assessment, Object.hashAll(plants), reference, now);

  @override
  String toString() => 'RecommendationInput(${assessment.id})';
}
