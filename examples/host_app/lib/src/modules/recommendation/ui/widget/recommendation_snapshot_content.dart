import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:host_app/src/core/navigation/route_screen.dart';
import 'package:host_app/src/modules/assessment/model/recommendation_snapshot.dart';
import 'package:host_app/src/modules/recommendation/ui/widget/recommendation_presentation.dart';
import 'package:host_app/src/modules/recommendation/ui/widget/suggestion_card.dart';
import 'package:host_app/src/shared/shared.dart';

/// What a recommendation found: a warning, the suggested plants with how to
/// take them, what the catalog does not cover and what was left out.
///
/// Shown on the recommendation screen and in the assistant's chat.
class RecommendationSnapshotContent extends StatelessWidget {
  const RecommendationSnapshotContent({super.key, required this.snapshot});

  final RecommendationSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = BotanicaColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        switch (snapshot.status) {
          RecommendationStatus.seeDoctor => NoticeCard(
            icon: Icons.local_hospital_outlined,
            color: colors.danger,
            title: RecommendationStrings.seeDoctor,
            body: RecommendationStrings.seeDoctorBody,
            items: [for (final hit in snapshot.redFlags) hit.summary],
          ),
          RecommendationStatus.needsInformation => NoticeCard(
            icon: Icons.help_outline,
            color: colors.caution,
            title: RecommendationStrings.needsInformation,
            items: [for (final item in snapshot.missing) item.label],
          ),
          RecommendationStatus.allExcluded => NoticeCard(
            icon: Icons.block,
            color: colors.caution,
            title: RecommendationStrings.allExcluded,
          ),
          RecommendationStatus.noMatch => NoticeCard(
            icon: Icons.search_off,
            color: colors.caution,
            title: RecommendationStrings.noMatch,
          ),
          RecommendationStatus.recommended => const SectionHeader(
            RecommendationStrings.recommended,
          ),
        },
        for (final suggestion in snapshot.suggestions)
          SuggestionCard(
            suggestion: suggestion,
            onOpenPlant: () => context.push(
              RouteScreen.plantDetail.pathFor(suggestion.plantId),
            ),
          ),
        if (snapshot.uncovered.isNotEmpty)
          NoticeCard(
            icon: Icons.info_outline,
            color: colors.caution,
            title: RecommendationStrings.uncovered,
            items: snapshot.uncovered,
          ),
        if (snapshot.excluded.isNotEmpty) ...[
          const SectionHeader(RecommendationStrings.excluded),
          LabeledList([for (final plant in snapshot.excluded) plant.summary]),
        ],
      ],
    );
  }
}
