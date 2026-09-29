import 'package:flutter/material.dart';

import 'package:host_app/src/modules/assessment/model/recommendation_snapshot.dart';
import 'package:host_app/src/modules/plant/ui/widget/preparation_section.dart';
import 'package:host_app/src/shared/shared.dart';

/// A recommended plant with its photo, so the person does not confuse it.
class SuggestionCard extends StatelessWidget {
  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.onOpenPlant,
  });

  final PlantSuggestion suggestion;

  final VoidCallback onOpenPlant;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // A lighter surface without a border: nested outlines read as clutter.
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => PhotoViewerDialog.show(
                      context,
                      ref: suggestion.photoRef,
                    ),
                    child: BotanicaPhoto(ref: suggestion.photoRef, size: 96),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(suggestion.commonName, style: text.titleLarge),
                        if (suggestion.scientificName.isNotEmpty)
                          Text(
                            suggestion.scientificName,
                            style: text.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${RecommendationStrings.helpsWith}: ${suggestion.matchedLine}',
                          style: text.bodyLarge,
                        ),
                        if (suggestion.popularOnly) ...[
                          const SizedBox(height: AppSpacing.xs),
                          StatusBadge(
                            label: PlantStrings.popular,
                            color: BotanicaColors.of(context).caution,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (suggestion.preparations.isNotEmpty) ...[
                const SectionHeader(PlantStrings.howToTake),
                PreparationSection(preparations: suggestion.preparations),
              ],
              if (suggestion.cautions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  RecommendationStrings.cautionWith,
                  style: text.titleSmall?.copyWith(
                    color: BotanicaColors.of(context).caution,
                  ),
                ),
                LabeledList(suggestion.cautions),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onOpenPlant,
                  child: const Text(RecommendationStrings.viewPlant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
