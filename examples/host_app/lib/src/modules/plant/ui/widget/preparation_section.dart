import 'package:flutter/material.dart';

import 'package:host_app/src/modules/plant/model/preparation.dart';
import 'package:host_app/src/modules/plant/ui/widget/preparation_guide.dart';
import 'package:host_app/src/shared/shared.dart';

/// Each way to take the plant, as a picture recipe.
class PreparationSection extends StatelessWidget {
  const PreparationSection({super.key, required this.preparations});

  final List<Preparation> preparations;

  @override
  Widget build(BuildContext context) => Column(
    spacing: AppSpacing.md,
    children: [
      for (final preparation in preparations)
        PreparationGuide(preparation: preparation),
    ],
  );
}
