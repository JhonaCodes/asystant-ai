import 'package:flutter/material.dart';

import 'package:host_app/src/modules/plant/model/plant.dart';
import 'package:host_app/src/modules/plant/ui/widget/origin_badge.dart';
import 'package:host_app/src/shared/shared.dart';

/// A plant in the list: photo, names and what it is used for.
class PlantCard extends StatelessWidget {
  const PlantCard({
    super.key,
    required this.plant,
    required this.onTap,
    this.selected = false,
  });

  final Plant plant;

  final VoidCallback onTap;

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected
            ? colors.secondaryContainer
            : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                BotanicaPhoto(ref: plant.mainPhoto?.ref ?? '', size: 64),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plant.commonName, style: text.titleMedium),
                      if (plant.scientificName.isNotEmpty)
                        Text(
                          plant.scientificName,
                          style: text.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        plant.usesLine,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                      if (!plant.isSeed) ...[
                        const SizedBox(height: AppSpacing.xs),
                        const OriginBadge(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
