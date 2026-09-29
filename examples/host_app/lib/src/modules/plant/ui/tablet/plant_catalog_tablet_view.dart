import 'package:flutter/material.dart';

import 'package:host_app/src/modules/plant/model/plant_catalog.dart';
import 'package:host_app/src/modules/plant/ui/view/plant_detail_view.dart';
import 'package:host_app/src/modules/plant/ui/widget/plant_list.dart';
import 'package:host_app/src/modules/plant/viewmodel/plant_catalog_viewmodel.dart';
import 'package:host_app/src/shared/shared.dart';

/// The list beside the selected plant.
class PlantCatalogTabletView extends StatelessWidget {
  const PlantCatalogTabletView({
    super.key,
    required this.catalog,
    required this.viewModel,
  });

  final PlantCatalog catalog;

  final PlantCatalogViewModel viewModel;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(PlantStrings.title),
      actions: const [AssistantAppBarAction()],
    ),
    body: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              PlantList(
                catalog: catalog,
                viewModel: viewModel,
                highlightsSelection: true,
                onOpen: (plant) => viewModel.select(plant.id),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: switch (catalog.selected) {
            final plant? => ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                PlantDetailView(plant: plant, labelOf: viewModel.labelOf),
              ],
            ),
            null => const EmptyState(
              icon: Icons.local_florist_outlined,
              message: PlantStrings.choose,
            ),
          },
        ),
      ],
    ),
  );
}
