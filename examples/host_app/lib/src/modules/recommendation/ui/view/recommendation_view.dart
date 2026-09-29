import 'package:flutter/material.dart';

import 'package:host_app/src/modules/assessment/model/assessment.dart';
import 'package:host_app/src/modules/profile/model/person_profile.dart';
import 'package:host_app/src/modules/recommendation/model/recommendation_run.dart';
import 'package:host_app/src/modules/recommendation/ui/widget/recommendation_snapshot_content.dart';
import 'package:host_app/src/modules/recommendation/viewmodel/recommendation_viewmodel.dart';
import 'package:host_app/src/shared/shared.dart';

/// The last recommendation of an assessment, and the action to (re)compute it.
class RecommendationView extends StatelessWidget {
  const RecommendationView({
    super.key,
    required this.assessment,
    required this.profile,
    required this.run,
    required this.viewModel,
  });

  final Assessment assessment;

  final PersonProfile profile;

  final RecommendationRun run;

  final RecommendationViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final computing = run.isComputing(assessment.id);
    final snapshot = assessment.recommendation;
    return BotanicaPage(
      title: RecommendationStrings.title,
      showsBack: true,
      children: [
        Text(assessment.reason, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        if (snapshot == null)
          const Text(RecommendationStrings.none)
        else ...[
          if (viewModel.isOutdated(assessment, profile))
            NoticeCard(
              icon: Icons.update,
              color: BotanicaColors.of(context).caution,
              title: RecommendationStrings.outdated,
            ),
          RecommendationSnapshotContent(snapshot: snapshot),
          Text(
            RecommendationStrings.calculatedOn(snapshot.generatedAt.shortDate),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: computing
              ? null
              : () => viewModel.recommend(assessment.id),
          icon: const Icon(Icons.eco_outlined),
          label: Text(switch ((computing, snapshot)) {
            (true, _) => RecommendationStrings.computing,
            (false, null) => RecommendationStrings.compute,
            (false, _) => RecommendationStrings.update,
          }),
        ),
        const DisclaimerNote(),
      ],
    );
  }
}
