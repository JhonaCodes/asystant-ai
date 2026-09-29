import 'package:flutter/material.dart';

import 'package:host_app/src/modules/assessment/model/assessment_log.dart';
import 'package:host_app/src/modules/assessment/ui/view/assessment_detail_view.dart';
import 'package:host_app/src/modules/assessment/ui/widget/assessment_tile.dart';
import 'package:host_app/src/modules/assessment/ui/widget/delete_assessment_action.dart';
import 'package:host_app/src/modules/assessment/viewmodel/assessment_viewmodel.dart';
import 'package:host_app/src/shared/shared.dart';

/// The list beside the selected consultation.
class AssessmentListTabletView extends StatelessWidget {
  const AssessmentListTabletView({
    super.key,
    required this.log,
    required this.viewModel,
  });

  final AssessmentLog log;

  final AssessmentViewModel viewModel;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(AssessmentStrings.title),
      actions: [
        if (log.selected case final selected?)
          DeleteAssessmentAction(
            assessmentId: selected.id,
            viewModel: viewModel,
          ),
        const AssistantAppBarAction(),
      ],
    ),
    body: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
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
                    selected: assessment.id == log.selectedId,
                    onTap: () => viewModel.select(assessment.id),
                  ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: switch (log.selected) {
            final assessment? => ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                AssessmentDetailView(
                  assessment: assessment,
                  viewModel: viewModel,
                ),
              ],
            ),
            null => const EmptyState(
              icon: Icons.assignment_outlined,
              message: AssessmentStrings.choose,
            ),
          },
        ),
      ],
    ),
  );
}
