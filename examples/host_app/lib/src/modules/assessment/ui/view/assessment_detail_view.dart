import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:host_app/src/core/navigation/route_screen.dart';
import 'package:host_app/src/modules/assessment/model/assessment.dart';
import 'package:host_app/src/modules/assessment/model/clinical_photo.dart';
import 'package:host_app/src/modules/assessment/ui/widget/assessment_presentation.dart';
import 'package:host_app/src/modules/assessment/ui/widget/clinical_photo_grid.dart';
import 'package:host_app/src/modules/assessment/ui/widget/symptom_card.dart';
import 'package:host_app/src/modules/assessment/viewmodel/assessment_viewmodel.dart';
import 'package:host_app/src/shared/shared.dart';

/// Everything recorded in one consultation.
class AssessmentDetailView extends StatelessWidget {
  const AssessmentDetailView({
    super.key,
    required this.assessment,
    required this.viewModel,
  });

  final Assessment assessment;

  final AssessmentViewModel viewModel;

  Future<void> _removePhoto(BuildContext context, ClinicalPhoto photo) async {
    final confirmed = await ConfirmDialog.ask(
      context,
      title: AssessmentStrings.removePhoto,
      body: AssessmentStrings.removePhotoBody,
      confirmLabel: AssessmentStrings.removePhoto,
    );
    if (confirmed) {
      await viewModel.removePhoto(assessment.id, photo.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(assessment.reason, style: text.titleLarge)),
            StatusBadge(
              label: assessment.status.label,
              color: assessment.status.colorIn(context),
            ),
          ],
        ),
        Text(assessment.createdAt.shortDate, style: text.bodySmall),
        if (assessment.redFlagIds.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          NoticeCard(
            icon: Icons.local_hospital_outlined,
            color: BotanicaColors.of(context).danger,
            title: AssessmentStrings.redFlags,
            body: AssessmentStrings.redFlagsBody,
            items: [
              for (final id in assessment.redFlagIds)
                viewModel.redFlagLabel(id),
            ],
          ),
        ],
        const SectionHeader(AssessmentStrings.symptoms),
        if (assessment.symptoms.isEmpty)
          const Text(AssessmentStrings.noSymptoms)
        else
          for (final symptom in assessment.symptoms)
            SymptomCard(symptom: symptom),
        const SectionHeader(AssessmentStrings.goals),
        if (assessment.goals.isEmpty)
          const Text(AssessmentStrings.noGoals)
        else
          LabeledList([for (final goal in assessment.goals) goal.description]),
        if (assessment.photos.isNotEmpty) ...[
          const SectionHeader(AssessmentStrings.photos),
          ClinicalPhotoGrid(
            photos: assessment.photos,
            onRemove: (photo) => _removePhoto(context, photo),
          ),
        ],
        if (assessment.summary.isNotEmpty) ...[
          const SectionHeader(AssessmentStrings.summary),
          Text(assessment.summary),
        ],
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: () =>
              context.push(RouteScreen.recommendation.pathFor(assessment.id)),
          icon: const Icon(Icons.eco_outlined),
          label: const Text(AssessmentStrings.viewRecommendation),
        ),
      ],
    );
  }
}
