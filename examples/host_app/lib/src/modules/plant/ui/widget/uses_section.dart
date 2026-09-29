import 'package:flutter/material.dart';

import 'package:host_app/src/modules/plant/model/plant_indication.dart';
import 'package:host_app/src/modules/plant/ui/widget/plant_presentation.dart';

/// Uses of the plant, each with how strong its support is.
class UsesSection extends StatelessWidget {
  const UsesSection({super.key, required this.uses});

  final List<PlantIndication> uses;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final use in uses)
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(Icons.eco_outlined),
          title: Text(use.label),
          subtitle: Text(use.detail),
        ),
    ],
  );
}
