import 'package:flutter/material.dart';

import 'package:host_app/src/modules/plant/model/preparation.dart';
import 'package:host_app/src/modules/plant/model/preparation_step.dart';
import 'package:host_app/src/modules/plant/ui/widget/plant_presentation.dart';
import 'package:host_app/src/modules/plant/ui/widget/preparation_illustration.dart';
import 'package:host_app/src/shared/shared.dart';

/// A preparation as a picture recipe: what it is, numbered steps with an
/// icon each, how much and how often, and what to be careful with.
///
/// Written for someone who will not read much: large text, one idea per
/// line, and the source's full explanation folded under "more details".
class PreparationGuide extends StatelessWidget {
  const PreparationGuide({super.key, required this.preparation});

  final Preparation preparation;

  @override
  Widget build(BuildContext context) {
    // A Material surface, so "more details" can show its touch feedback.
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [
            _GuideHeader(preparation: preparation),
            if (preparation.steps.isEmpty)
              Text(
                preparation.instructions,
                style: Theme.of(context).textTheme.bodyLarge,
              )
            else
              Column(
                spacing: AppSpacing.sm,
                children: [
                  for (final (index, step) in preparation.steps.indexed)
                    _GuideStep(number: index + 1, step: step),
                ],
              ),
            _GuideFacts(preparation: preparation),
            if (preparation.warnings.isNotEmpty)
              _GuideWarnings(warnings: preparation.warnings),
            if (preparation.steps.isNotEmpty)
              _GuideDetails(text: preparation.instructions),
          ],
        ),
      ),
    );
  }
}

/// The picture, the plain name, and how it is taken.
class _GuideHeader extends StatelessWidget {
  const _GuideHeader({required this.preparation});

  final Preparation preparation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: .5),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: PreparationIllustration(scene: preparation.scene),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              Text(
                preparation.displayTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _GuideChip(
                    icon: preparation.route.icon,
                    label: preparation.route.label,
                  ),
                  if (preparation.needsBoilingWater)
                    const _GuideChip(
                      icon: Icons.local_fire_department_outlined,
                      label: PlantStrings.boilingWater,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuideChip extends StatelessWidget {
  const _GuideChip({required this.icon, required this.label});

  final IconData icon;

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xs,
          children: [
            Icon(icon, size: 18, color: colors.primary),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

/// "1 · 🔥 Hierve agua."
class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.number, required this.step});

  final int number;

  final PreparationStep step;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: PlantStrings.step(number),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            child: Text(
              '$number',
              style: text.titleSmall?.copyWith(color: colors.onPrimary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(step.kind.icon, size: 28, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(step.text, style: text.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }
}

/// How much, how often and for how long, one line each.
class _GuideFacts extends StatelessWidget {
  const _GuideFacts({required this.preparation});

  final Preparation preparation;

  @override
  Widget build(BuildContext context) => Column(
    spacing: AppSpacing.xs,
    children: [
      if (preparation.dose.isNotEmpty)
        _GuideFact(
          icon: Icons.inventory_2_outlined,
          label: PlantStrings.howMuch,
          value: preparation.dose,
        ),
      if (preparation.frequency.isNotEmpty)
        _GuideFact(
          icon: Icons.schedule,
          label: PlantStrings.howOften,
          value: preparation.frequency,
        ),
      if (preparation.maxDays case final days?)
        _GuideFact(
          icon: Icons.event_outlined,
          label: PlantStrings.maxDays(days),
          value: '',
        ),
    ],
  );
}

class _GuideFact extends StatelessWidget {
  const _GuideFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;

  final String label;

  /// Empty when the label says it all.
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (value.isNotEmpty) TextSpan(text: ': $value'),
              ],
            ),
            style: text.bodyLarge,
          ),
        ),
      ],
    );
  }
}

/// The cautions, apart and in the caution color.
class _GuideWarnings extends StatelessWidget {
  const _GuideWarnings({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    final caution = BotanicaColors.of(context).caution;
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: caution.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: caution),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  Text(
                    PlantStrings.careful,
                    style: text.titleSmall?.copyWith(color: caution),
                  ),
                  for (final warning in warnings)
                    Text(warning, style: text.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The source's full explanation, folded until the person asks for it.
class _GuideDetails extends StatelessWidget {
  const _GuideDetails({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      title: Text(
        PlantStrings.moreDetails,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      children: [Text(text)],
    ),
  );
}
