import 'package:flutter/material.dart';

import 'package:host_app/src/modules/plant/model/plant_botany.dart';
import 'package:host_app/src/shared/shared.dart';

/// What botany says: where it comes from, how it looks, how to grow it and
/// what it can be confused with.
class BotanySection extends StatelessWidget {
  const BotanySection({super.key, required this.botany});

  final PlantBotany botany;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: AppSpacing.md,
    children: [
      if (botany.description.isNotEmpty) Text(botany.description),
      if (botany.nativeRange.isNotEmpty)
        _BotanyItem(
          icon: Icons.public,
          title: PlantStrings.nativeRange,
          text: botany.nativeRange,
        ),
      if (botany.identification.isNotEmpty)
        _BotanyItem(
          icon: Icons.search,
          title: PlantStrings.identification,
          text: botany.identification,
        ),
      if (botany.cultivation.isNotEmpty)
        _BotanyItem(
          icon: Icons.yard_outlined,
          title: PlantStrings.cultivation,
          text: botany.cultivation,
        ),
      if (botany.lookalikes.isNotEmpty)
        NoticeCard(
          icon: Icons.warning_amber_rounded,
          color: BotanicaColors.of(context).caution,
          title: PlantStrings.lookalikes,
          items: botany.lookalikes,
        ),
    ],
  );
}

class _BotanyItem extends StatelessWidget {
  const _BotanyItem({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;

  final String title;

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            Text(text),
          ],
        ),
      ),
    ],
  );
}
