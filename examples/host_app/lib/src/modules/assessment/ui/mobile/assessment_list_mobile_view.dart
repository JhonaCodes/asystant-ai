import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:host_app/src/core/navigation/route_screen.dart';
import 'package:host_app/src/modules/assessment/model/assessment_log.dart';
import 'package:host_app/src/modules/assessment/ui/widget/assessment_tile.dart';
import 'package:host_app/src/shared/shared.dart';

class AssessmentListMobileView extends StatelessWidget {
  const AssessmentListMobileView({super.key, required this.log});

  final AssessmentLog log;

  @override
  Widget build(BuildContext context) => BotanicaPage(
    title: AssessmentStrings.title,
    children: [
      if (log.items.isEmpty)
        const EmptyState(
          icon: Icons.assignment_outlined,
          message: AssessmentStrings.empty,
        )
      else
        for (final assessment in log.items)
          AssessmentTile(
            assessment: assessment,
            onTap: () => context.push(
              RouteScreen.assessmentDetail.pathFor(assessment.id),
            ),
          ),
    ],
  );
}
