import 'package:flutter/material.dart';

import 'package:host_app/src/modules/plant/model/plant_belief.dart';
import 'package:host_app/src/shared/shared.dart';

/// Popular beliefs that are not safe to act on, each with what is known.
class BeliefsSection extends StatelessWidget {
  const BeliefsSection({super.key, required this.beliefs});

  final List<PlantBelief> beliefs;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: AppSpacing.sm,
    children: [
      Text(PlantStrings.beliefs, style: Theme.of(context).textTheme.titleSmall),
      for (final belief in beliefs) _Belief(belief: belief),
    ],
  );
}

class _Belief extends StatelessWidget {
  const _Belief({required this.belief});

  final PlantBelief belief;

  @override
  Widget build(BuildContext context) {
    final danger = BotanicaColors.of(context).danger;
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: danger.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.do_not_disturb_on_outlined, color: danger),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('«${belief.claim}»', style: text.titleSmall),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${PlantStrings.known}: ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: belief.note),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
