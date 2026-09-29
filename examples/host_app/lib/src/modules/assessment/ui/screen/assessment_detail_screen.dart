import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'package:host_app/src/modules/assessment/model/assessment_log.dart';
import 'package:host_app/src/modules/assessment/ui/view/assessment_detail_view.dart';
import 'package:host_app/src/modules/assessment/ui/widget/delete_assessment_action.dart';
import 'package:host_app/src/modules/assessment/viewmodel/assessment_viewmodel.dart';
import 'package:host_app/src/shared/shared.dart';

/// One consultation on its own page (phones).
class AssessmentDetailScreen extends StatelessWidget {
  const AssessmentDetailScreen({super.key, required this.assessmentId});

  final String assessmentId;

  @override
  Widget build(
    BuildContext context,
  ) => ReactiveAsyncBuilder<AssessmentViewModel, AssessmentLog>(
    notifier: AssessmentService.notifier,
    onLoading: () => const BotanicaPage(
      title: AssessmentStrings.detail,
      showsBack: true,
      children: [LoadingView()],
    ),
    onError: (_, _) => BotanicaPage(
      title: AssessmentStrings.detail,
      showsBack: true,
      children: [ErrorView(onRetry: AssessmentService.notifier.reload)],
    ),
    onData: (log, viewModel, keep) => switch (log.byId(assessmentId)) {
      final assessment? => BotanicaPage(
        title: AssessmentStrings.detail,
        showsBack: true,
        actions: [
          DeleteAssessmentAction(
            assessmentId: assessment.id,
            viewModel: viewModel,
            onDeleted: () => context.pop(),
          ),
        ],
        children: [
          AssessmentDetailView(assessment: assessment, viewModel: viewModel),
        ],
      ),
      null => const BotanicaPage(
        title: AssessmentStrings.detail,
        showsBack: true,
        children: [
          EmptyState(icon: Icons.search_off, message: CommonStrings.notFound),
        ],
      ),
    },
  );
}
