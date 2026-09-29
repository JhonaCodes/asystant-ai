import 'package:flutter/material.dart';

import 'package:host_app/src/modules/plant/model/plant.dart';
import 'package:host_app/src/modules/plant/model/plant_enums.dart';
import 'package:host_app/src/modules/plant/ui/widget/plant_presentation.dart';
import 'package:host_app/src/shared/shared.dart';

/// When not to take the plant: pregnancy, age, conditions, medicines,
/// allergies and possible effects.
class PrecautionsSection extends StatelessWidget {
  const PrecautionsSection({
    super.key,
    required this.plant,
    required this.labelOf,
  });

  final Plant plant;

  /// Readable name of a condition, medicine class or allergen tag.
  final String Function(String tag) labelOf;

  @override
  Widget build(BuildContext context) {
    final colors = BotanicaColors.of(context);
    return BotanicaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Guidance(title: PlantStrings.pregnancy, guidance: plant.pregnancy),
          _Guidance(title: PlantStrings.lactation, guidance: plant.lactation),
          if (plant.minAgeYears case final years?)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(PlantStrings.minAge(years)),
            ),
          for (final item in plant.contraindications)
            _Line(color: colors.danger, text: item.describe(labelOf)),
          for (final item in plant.interactions)
            _Line(color: item.colorIn(context), text: item.describe(labelOf)),
          if (plant.allergenGroups.isNotEmpty)
            _Line(color: colors.caution, text: plant.allergensLine(labelOf)),
          if (plant.sideEffects.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              PlantStrings.sideEffects,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            LabeledList(plant.sideEffects),
          ],
        ],
      ),
    );
  }
}

class _Guidance extends StatelessWidget {
  const _Guidance({required this.title, required this.guidance});

  final String title;

  final SafetyGuidance guidance;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      children: [
        Text('$title: '),
        Flexible(
          child: StatusBadge(
            label: guidance.label,
            color: guidance.colorIn(context),
          ),
        ),
      ],
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.color, required this.text});

  final Color color;

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
          child: Icon(Icons.circle, size: 8, color: color),
        ),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
