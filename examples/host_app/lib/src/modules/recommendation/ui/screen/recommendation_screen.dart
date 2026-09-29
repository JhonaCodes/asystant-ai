import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'package:host_app/src/integrations/device/device.dart';
import 'package:host_app/src/modules/assessment/model/assessment_log.dart';
import 'package:host_app/src/modules/assessment/viewmodel/assessment_viewmodel.dart';
import 'package:host_app/src/modules/profile/model/person_profile.dart';
import 'package:host_app/src/modules/profile/viewmodel/profile_viewmodel.dart';
import 'package:host_app/src/modules/recommendation/model/recommendation_run.dart';
import 'package:host_app/src/modules/recommendation/ui/view/recommendation_view.dart';
import 'package:host_app/src/modules/recommendation/viewmodel/recommendation_viewmodel.dart';
import 'package:host_app/src/shared/shared.dart';

/// The assessment, the profile it depends on and the run in progress.
class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({super.key, required this.assessmentId});

  final String assessmentId;

  @override
  Widget build(BuildContext context) =>
      ReactiveAsyncBuilder<ProfileViewModel, PersonProfile>(
        notifier: ProfileService.notifier,
        onLoading: () => const _Frame(child: LoadingView()),
        onError: (_, _) =>
            _Frame(child: ErrorView(onRetry: ProfileService.notifier.reload)),
        onData: (profile, _, keep) =>
            ReactiveAsyncBuilder<AssessmentViewModel, AssessmentLog>(
              notifier: AssessmentService.notifier,
              onLoading: () => const _Frame(child: LoadingView()),
              onError: (_, _) => _Frame(
                child: ErrorView(onRetry: AssessmentService.notifier.reload),
              ),
              onData: (log, _, keep) =>
                  ReactiveViewModelBuilder<
                    RecommendationViewModel,
                    RecommendationRun
                  >(
                    viewmodel: RecommendationService.notifier,
                    build: (run, viewModel, keep) =>
                        switch (log.byId(assessmentId)) {
                          final assessment? => DeviceLayout(
                            mobile: RecommendationView(
                              assessment: assessment,
                              profile: profile,
                              run: run,
                              viewModel: viewModel,
                            ),
                          ),
                          null => const _Frame(
                            child: EmptyState(
                              icon: Icons.search_off,
                              message: CommonStrings.notFound,
                            ),
                          ),
                        },
                  ),
            ),
      );
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => BotanicaPage(
    title: RecommendationStrings.title,
    showsBack: true,
    children: [child],
  );
}
