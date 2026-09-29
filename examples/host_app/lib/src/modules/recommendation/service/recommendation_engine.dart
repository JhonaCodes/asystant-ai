import 'dart:convert';

import 'package:host_app/src/modules/assessment/model/assessment.dart';
import 'package:host_app/src/modules/assessment/model/recommendation_snapshot.dart';
import 'package:host_app/src/modules/plant/model/plant.dart';
import 'package:host_app/src/modules/plant/model/plant_enums.dart';
import 'package:host_app/src/modules/profile/model/biological_sex.dart';
import 'package:host_app/src/modules/profile/model/person_profile.dart';
import 'package:host_app/src/modules/reference/model/red_flag_rule.dart';
import 'package:host_app/src/modules/recommendation/model/recommendation_input.dart';

/// Recommends plants from data only, the same way every time.
///
/// 1. A warning sign stops everything: see a doctor, no plants.
/// 2. Missing age, pregnancy or lactation stops it too: the assistant must
///    ask first.
/// 3. Plants whose indications cover the symptom and goal tags are
///    candidates; plants the person added are not verified and are left out.
/// 4. A candidate is excluded for age, pregnancy, lactation, a condition, an
///    allergy or a medicine to avoid; a medicine to use with caution only
///    adds a caution.
/// 5. The rest are ranked by evidence and coverage; the first five remain.
abstract final class RecommendationEngine {
  static const maxSuggestions = 5;

  /// Ages in which pregnancy and lactation must be asked about.
  static const _fertileFrom = 12;
  static const _fertileTo = 55;

  static RecommendationSnapshot evaluate(RecommendationInput input) {
    final basis = basisOf(input.profile, input.assessment);
    RecommendationSnapshot result(
      RecommendationStatus status, {
      List<RedFlagHit> redFlags = const [],
      List<PlantSuggestion> suggestions = const [],
      List<ExcludedPlant> excluded = const [],
      List<String> uncovered = const [],
      List<MissingData> missing = const [],
    }) => RecommendationSnapshot(
      status: status,
      generatedAt: input.now,
      redFlags: redFlags,
      suggestions: suggestions,
      excluded: excluded,
      uncovered: uncovered,
      missing: missing,
      basis: basis,
      referenceVersion: input.reference.version,
    );

    final hits = _redFlags(input);
    if (hits.isNotEmpty) {
      return result(RecommendationStatus.seeDoctor, redFlags: hits);
    }
    final missing = _missing(input);
    if (missing.isNotEmpty) {
      return result(RecommendationStatus.needsInformation, missing: missing);
    }
    final wanted = input.assessment.wantedTags;
    final curated = [
      for (final plant in input.plants)
        if (plant.origin == PlantOrigin.seed) plant,
    ]..sort((a, b) => a.id.compareTo(b.id));
    final candidates = [
      for (final plant in input.plants)
        if (plant.indications.any((item) => wanted.contains(item.tag))) plant,
    ]..sort((a, b) => a.id.compareTo(b.id));

    final suggestions = <PlantSuggestion>[];
    final excluded = <ExcludedPlant>[];
    for (final plant in candidates) {
      final reasons = _exclusions(plant, input);
      if (reasons.isEmpty) {
        suggestions.add(_suggestion(plant, input, wanted));
      } else {
        excluded.add(
          ExcludedPlant(
            plantId: plant.id,
            commonName: plant.commonName,
            reasons: reasons,
          ),
        );
      }
    }
    suggestions.sort(
      (a, b) => b.score != a.score
          ? b.score.compareTo(a.score)
          : a.commonName.compareTo(b.commonName),
    );
    final covered = {
      for (final plant in curated)
        for (final indication in plant.indications) indication.tag,
    };
    final uncovered = [
      for (final tag in wanted.toList()..sort())
        if (!covered.contains(tag)) input.reference.labelOf(tag),
    ];
    final status = switch ((suggestions.isEmpty, candidates.isEmpty)) {
      (false, _) => RecommendationStatus.recommended,
      (true, false) => RecommendationStatus.allExcluded,
      (true, true) => RecommendationStatus.noMatch,
    };
    return result(
      status,
      suggestions: suggestions.take(maxSuggestions).toList(),
      excluded: excluded,
      uncovered: uncovered,
    );
  }

  /// A fingerprint of every datum the recommendation depends on.
  static String basisOf(PersonProfile profile, Assessment assessment) =>
      jsonEncode({
        'birthDate': profile.birthDate?.toIso8601String(),
        'sex': profile.sex.name,
        'pregnant': profile.isPregnant,
        'lactating': profile.isLactating,
        'conditions': profile.conditionTags.toList()..sort(),
        'medications': profile.medicationClasses.toList()..sort(),
        'allergies': profile.allergyTags.toList()..sort(),
        'symptoms': [
          for (final symptom in assessment.symptoms)
            [symptom.tag, symptom.intensity, symptom.durationDays],
        ],
        'goals': assessment.goals.map((goal) => goal.tag).toList(),
        'redFlags': assessment.redFlagIds.toList()..sort(),
      });

  static List<RedFlagHit> _redFlags(RecommendationInput input) {
    final age = input.age;
    return [
      for (final rule in input.reference.redFlags)
        if (input.assessment.redFlagIds.contains(rule.id) ||
            _fires(rule, input.assessment, age))
          RedFlagHit(ruleId: rule.id, label: rule.label, advice: rule.advice),
    ];
  }

  static bool _fires(RedFlagRule rule, Assessment assessment, int? age) {
    final maxAge = rule.maxAgeYears;
    if (maxAge != null && (age == null || age > maxAge)) {
      return false;
    }
    return assessment.symptoms.any(
      (symptom) =>
          (rule.anySymptom || rule.triggerTags.contains(symptom.tag)) &&
          (symptom.intensity ?? 0) >= (rule.minIntensity ?? 0) &&
          (symptom.durationDays ?? 0) >= (rule.minDurationDays ?? 0),
    );
  }

  static List<MissingData> _missing(RecommendationInput input) {
    final profile = input.profile;
    final age = input.age;
    final asksReproductive =
        profile.sex != BiologicalSex.male &&
        (age == null || (age >= _fertileFrom && age <= _fertileTo));
    return [
      if (input.assessment.wantedTags.isEmpty) MissingData.symptoms,
      if (age == null) MissingData.age,
      if (asksReproductive && profile.isPregnant == null) MissingData.pregnancy,
      if (asksReproductive && profile.isLactating == null)
        MissingData.lactation,
    ];
  }

  static List<ExclusionReason> _exclusions(
    Plant plant,
    RecommendationInput input,
  ) {
    final profile = input.profile;
    final age = input.age;
    final label = input.reference.labelOf;
    final allergies = profile.allergyTags;
    final minAge = plant.minAgeYears;
    return [
      if (plant.origin == PlantOrigin.person)
        const ExclusionReason(kind: ExclusionKind.notCurated),
      if (minAge != null && age != null && age < minAge)
        ExclusionReason(kind: ExclusionKind.age, detail: '$minAge'),
      if (profile.isPregnant == true &&
          plant.pregnancy != SafetyGuidance.acceptable)
        const ExclusionReason(kind: ExclusionKind.pregnancy),
      if (profile.isLactating == true &&
          plant.lactation != SafetyGuidance.acceptable)
        const ExclusionReason(kind: ExclusionKind.lactation),
      for (final item in plant.contraindications)
        if (item.kind == ContraindicationKind.condition &&
            profile.conditionTags.contains(item.tag))
          ExclusionReason(
            kind: ExclusionKind.condition,
            detail: label(item.tag),
          )
        else if (item.kind == ContraindicationKind.allergy &&
            allergies.contains(item.tag))
          ExclusionReason(kind: ExclusionKind.allergy, detail: label(item.tag)),
      for (final group in plant.allergenGroups)
        if (allergies.contains(group))
          ExclusionReason(kind: ExclusionKind.allergy, detail: label(group)),
      for (final item in plant.interactions)
        if (item.severity == InteractionSeverity.avoid &&
            profile.medicationClasses.contains(item.medicationClass))
          ExclusionReason(
            kind: ExclusionKind.interaction,
            detail: label(item.medicationClass),
          ),
    ];
  }

  static PlantSuggestion _suggestion(
    Plant plant,
    RecommendationInput input,
    Set<String> wanted,
  ) {
    final matched = [
      for (final indication in plant.indications)
        if (wanted.contains(indication.tag)) indication,
    ];
    final score =
        matched.fold(0, (sum, item) => sum + item.evidence.weight) +
        matched.map((item) => item.tag).toSet().length;
    return PlantSuggestion(
      plantId: plant.id,
      commonName: plant.commonName,
      scientificName: plant.scientificName,
      photoRef: plant.mainPhoto?.ref ?? '',
      score: score,
      matched: [for (final item in matched) item.label],
      popularOnly: matched.every((item) => item.isPopular),
      easyExplanation: plant.easyExplanation,
      preparations: plant.preparationsFor({
        for (final item in matched) item.tag,
      }),
      cautions: [
        for (final item in plant.interactions)
          if (item.severity == InteractionSeverity.caution &&
              input.profile.medicationClasses.contains(item.medicationClass))
            [
              input.reference.labelOf(item.medicationClass),
              item.note,
            ].where((part) => part.isNotEmpty).join(': '),
      ],
    );
  }
}
