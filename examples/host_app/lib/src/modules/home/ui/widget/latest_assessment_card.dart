import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'package:host_app/src/core/navigation/route_screen.dart';
import 'package:host_app/src/modules/assessment/model/assessment_log.dart';
import 'package:host_app/src/modules/assessment/viewmodel/assessment_viewmodel.dart';
import 'package:host_app/src/modules/home/ui/widget/summary_card.dart';
import 'package:host_app/src/shared/shared.dart';

class LatestAssessmentCard extends StatelessWidget {
  const LatestAssessmentCard({super.key});

  @override
  Widget build(BuildContext context) =>
      ReactiveAsyncBuilder<AssessmentViewModel, AssessmentLog>(
        notifier: AssessmentService.notifier,
        onLoading: () => const SizedBox.shrink(),
        onError: (_, _) => const SizedBox.shrink(),
        onData: (log, _, keep) => SummaryCard(
          icon: Icons.assignment_outlined,
          title: HomeStrings.latest,
          value: switch (log.latest) {
            final latest? => '${latest.reason} · ${latest.createdAt.shortDate}',
            null => HomeStrings.latestEmpty,
          },
          onTap: () => context.go(RouteScreen.assessments.path),
        ),
      );
}
