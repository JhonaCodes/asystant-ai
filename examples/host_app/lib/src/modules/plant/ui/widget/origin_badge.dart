import 'package:flutter/material.dart';

import 'package:host_app/src/shared/shared.dart';

/// Marks a plant the person added, whose safety data is not verified.
class OriginBadge extends StatelessWidget {
  const OriginBadge({super.key});

  @override
  Widget build(BuildContext context) => StatusBadge(
    label: PlantStrings.addedBadge,
    color: BotanicaColors.of(context).person,
  );
}
