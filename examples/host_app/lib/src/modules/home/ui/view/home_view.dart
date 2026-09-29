import 'package:flutter/material.dart';

import 'package:host_app/src/modules/home/ui/widget/catalog_summary_card.dart';
import 'package:host_app/src/modules/home/ui/widget/latest_assessment_card.dart';
import 'package:host_app/src/modules/home/ui/widget/profile_summary_card.dart';
import 'package:host_app/src/shared/shared.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) => BotanicaPage(
    title: CommonStrings.appName,
    children: [
      Text(
        HomeStrings.greeting,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: AppSpacing.sm),
      const Text(HomeStrings.intro),
      const SizedBox(height: AppSpacing.lg),
      const ProfileSummaryCard(),
      const LatestAssessmentCard(),
      const CatalogSummaryCard(),
      const DisclaimerNote(),
    ],
  );
}
