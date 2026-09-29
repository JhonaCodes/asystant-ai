import 'package:flutter/material.dart';

import 'package:host_app/src/modules/plant/model/plant.dart';
import 'package:host_app/src/modules/plant/model/plant_enums.dart';
import 'package:host_app/src/modules/plant/ui/widget/beliefs_section.dart';
import 'package:host_app/src/modules/plant/ui/widget/botany_section.dart';
import 'package:host_app/src/modules/plant/ui/widget/origin_badge.dart';
import 'package:host_app/src/modules/plant/ui/widget/plant_presentation.dart';
import 'package:host_app/src/modules/plant/ui/widget/plant_photo_strip.dart';
import 'package:host_app/src/modules/plant/ui/widget/precautions_section.dart';
import 'package:host_app/src/modules/plant/ui/widget/preparation_section.dart';
import 'package:host_app/src/modules/plant/ui/widget/sources_section.dart';
import 'package:host_app/src/modules/plant/ui/widget/uses_section.dart';
import 'package:host_app/src/shared/shared.dart';

/// Everything about one plant, top to bottom.
class PlantDetailView extends StatelessWidget {
  const PlantDetailView({
    super.key,
    required this.plant,
    required this.labelOf,
  });

  final Plant plant;

  final String Function(String tag) labelOf;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlantPhotoStrip(photos: plant.photos),
        const SizedBox(height: AppSpacing.md),
        Text(plant.commonName, style: text.headlineSmall),
        if (plant.botanicalLine.isNotEmpty)
          Text(
            plant.botanicalLine,
            style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
          ),
        if (!plant.isSeed) ...[
          const SizedBox(height: AppSpacing.sm),
          const OriginBadge(),
        ],
        if (plant.hasNoSafeUse) ...[
          const SizedBox(height: AppSpacing.md),
          NoticeCard(
            icon: Icons.dangerous_outlined,
            color: BotanicaColors.of(context).danger,
            title: PlantStrings.noSafeUse,
            body: PlantStrings.noSafeUseBody,
          ),
        ],
        if (plant.easyExplanation.isNotEmpty) ...[
          const SectionHeader(PlantStrings.inShort),
          Text(plant.easyExplanation),
        ],
        if (!plant.botany.isEmpty) ...[
          const SectionHeader(PlantStrings.botany),
          BotanySection(botany: plant.botany),
        ],
        if (plant.scienceUses.isNotEmpty) ...[
          const SectionHeader(PlantStrings.science),
          UsesSection(uses: plant.scienceUses),
        ],
        if (plant.popularUses.isNotEmpty || plant.beliefs.isNotEmpty) ...[
          const SectionHeader(PlantStrings.popularUses),
          NoticeCard(
            icon: Icons.forum_outlined,
            color: BotanicaColors.of(context).caution,
            title: PlantStrings.popularNote,
          ),
          UsesSection(uses: plant.popularUses),
          if (plant.beliefs.isNotEmpty) BeliefsSection(beliefs: plant.beliefs),
        ],
        if (plant.preparations.isNotEmpty) ...[
          const SectionHeader(PlantStrings.howToTake),
          PreparationSection(preparations: plant.preparations),
        ],
        const SectionHeader(PlantStrings.precautions),
        PrecautionsSection(plant: plant, labelOf: labelOf),
        if (plant.sources.isNotEmpty) ...[
          const SectionHeader(PlantStrings.sources),
          for (final kind in SourceKind.values)
            if (plant.sourcesOf(kind) case final sources
                when sources.isNotEmpty) ...[
              Text(kind.label, style: text.titleSmall),
              SourcesSection(sources: sources),
            ],
        ],
      ],
    );
  }
}
