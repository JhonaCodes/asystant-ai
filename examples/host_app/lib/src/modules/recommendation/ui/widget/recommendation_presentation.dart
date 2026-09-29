import 'package:host_app/src/modules/assessment/model/recommendation_snapshot.dart';
import 'package:host_app/src/shared/shared.dart';

extension MissingDataLabel on MissingData {
  String get label => switch (this) {
    MissingData.age => RecommendationStrings.missingAge,
    MissingData.pregnancy => RecommendationStrings.missingPregnancy,
    MissingData.lactation => RecommendationStrings.missingLactation,
    MissingData.symptoms => RecommendationStrings.missingSymptoms,
  };
}

extension ExclusionReasonLabel on ExclusionReason {
  String get label {
    final lead = switch (kind) {
      ExclusionKind.age => RecommendationStrings.minAge(detail),
      ExclusionKind.pregnancy => RecommendationStrings.reasonPregnancy,
      ExclusionKind.lactation => RecommendationStrings.reasonLactation,
      ExclusionKind.condition => RecommendationStrings.reasonCondition,
      ExclusionKind.allergy => RecommendationStrings.reasonAllergy,
      ExclusionKind.interaction => RecommendationStrings.reasonInteraction,
      ExclusionKind.notCurated => RecommendationStrings.reasonNotCurated,
    };
    final showsDetail = switch (kind) {
      ExclusionKind.condition ||
      ExclusionKind.allergy ||
      ExclusionKind.interaction => detail.isNotEmpty,
      ExclusionKind.age ||
      ExclusionKind.pregnancy ||
      ExclusionKind.lactation ||
      ExclusionKind.notCurated => false,
    };
    return showsDetail ? '$lead: $detail' : lead;
  }
}

extension ExcludedPlantLabel on ExcludedPlant {
  String get summary =>
      '$commonName — ${reasons.map((reason) => reason.label).join('; ')}';
}

extension RedFlagHitLabel on RedFlagHit {
  String get summary => '$label: $advice';
}
