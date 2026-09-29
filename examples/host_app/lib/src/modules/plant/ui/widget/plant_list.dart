import 'package:flutter/material.dart';

import 'package:host_app/src/modules/plant/model/plant.dart';
import 'package:host_app/src/modules/plant/model/plant_catalog.dart';
import 'package:host_app/src/modules/plant/ui/widget/plant_card.dart';
import 'package:host_app/src/modules/plant/viewmodel/plant_catalog_viewmodel.dart';
import 'package:host_app/src/shared/shared.dart';

/// Search, origin filter and the matching plants.
class PlantList extends StatelessWidget {
  const PlantList({
    super.key,
    required this.catalog,
    required this.viewModel,
    required this.onOpen,
    this.highlightsSelection = false,
  });

  final PlantCatalog catalog;

  final PlantCatalogViewModel viewModel;

  final ValueChanged<Plant> onOpen;

  final bool highlightsSelection;

  @override
  Widget build(BuildContext context) {
    final plants = catalog.visible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          initialValue: catalog.query,
          onChanged: viewModel.search,
          decoration: const InputDecoration(
            hintText: PlantStrings.search,
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final (filter, label) in const [
              (PlantOriginFilter.all, PlantStrings.all),
              (PlantOriginFilter.seed, PlantStrings.fromCatalog),
              (PlantOriginFilter.person, PlantStrings.addedByYou),
            ])
              ChoiceChip(
                label: Text(label),
                selected: catalog.filter == filter,
                onSelected: (_) => viewModel.showOrigin(filter),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (plants.isEmpty)
          const EmptyState(
            icon: Icons.local_florist_outlined,
            message: PlantStrings.empty,
          )
        else
          for (final plant in plants)
            PlantCard(
              plant: plant,
              selected: highlightsSelection && plant.id == catalog.selectedId,
              onTap: () => onOpen(plant),
            ),
      ],
    );
  }
}
