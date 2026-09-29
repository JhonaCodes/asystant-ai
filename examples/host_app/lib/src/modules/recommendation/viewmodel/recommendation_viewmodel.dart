import 'dart:async';

import 'package:logger_rs/logger_rs.dart';
import 'package:reactive_notifier/reactive_notifier.dart';
import 'package:result_controller/result_controller.dart';

import 'package:host_app/src/core/network/api_failure.dart';

import 'package:host_app/src/modules/assessment/model/assessment.dart';
import 'package:host_app/src/modules/assessment/model/recommendation_snapshot.dart';
import 'package:host_app/src/modules/assessment/repository/assessment_repository.dart';
import 'package:host_app/src/modules/assessment/viewmodel/assessment_viewmodel.dart';
import 'package:host_app/src/modules/plant/repository/plant_repository.dart';
import 'package:host_app/src/modules/profile/repository/profile_repository.dart';
import 'package:host_app/src/modules/profile/model/person_profile.dart';
import 'package:host_app/src/modules/recommendation/model/recommendation_input.dart';
import 'package:host_app/src/modules/recommendation/model/recommendation_run.dart';
import 'package:host_app/src/modules/recommendation/service/recommendation_engine.dart';
import 'package:host_app/src/modules/reference/repository/reference_repository.dart';

/// Runs the engine for an assessment and saves the result in it.
class RecommendationViewModel extends ViewModel<RecommendationRun> {
  RecommendationViewModel() : super(const RecommendationRun());

  AssessmentRepository get _assessments => const AssessmentRepository();

  ProfileRepository get _profiles => const ProfileRepository();

  PlantRepository get _plants => const PlantRepository();

  ReferenceRepository get _reference => const ReferenceRepository();

  @override
  void init() {}

  /// Reads fresh data, evaluates and stores the snapshot in the assessment.
  Future<Result<RecommendationSnapshot, ApiFailure>> recommend(
    String assessmentId,
  ) async {
    updateState(data.copyWith(computingId: assessmentId));
    final (assessment, profile, plants, reference) = await (
      _assessments.fetch(assessmentId),
      _profiles.fetch(),
      _plants.fetchAll(),
      _reference.fetch(),
    ).wait;
    final input = assessment.flatMap(
      (assessment) => profile.flatMap(
        (profile) => plants.flatMap(
          (plants) => reference.map(
            (reference) => RecommendationInput(
              profile: profile,
              assessment: assessment,
              plants: plants,
              reference: reference,
              now: DateTime.now().toUtc(),
            ),
          ),
        ),
      ),
    );
    final snapshot = input.map(RecommendationEngine.evaluate);
    final saved = await snapshot.when(
      ok: (snapshot) async {
        final stored = await AssessmentService.notifier.saveRecommendation(
          assessmentId,
          snapshot,
        );
        return stored.map((_) => snapshot);
      },
      err: (failure) async => Err<RecommendationSnapshot, ApiFailure>(failure),
    );
    if (saved.errorOrNull case final ApiFailure failure) {
      Log.w('Recommendation for $assessmentId failed: ${failure.msm}');
    }
    // Another assessment may have started computing meanwhile.
    if (data.isComputing(assessmentId)) {
      updateState(data.copyWith(clear: true));
    }
    return saved;
  }

  /// Whether the profile or the assessment changed since the last result.
  bool isOutdated(Assessment assessment, PersonProfile profile) =>
      switch (assessment.recommendation) {
        final snapshot? =>
          snapshot.basis != RecommendationEngine.basisOf(profile, assessment),
        null => false,
      };
}

mixin RecommendationService {
  static final ReactiveNotifier<RecommendationViewModel> run =
      ReactiveNotifier<RecommendationViewModel>(RecommendationViewModel.new);

  static RecommendationViewModel get notifier => run.notifier;
}
