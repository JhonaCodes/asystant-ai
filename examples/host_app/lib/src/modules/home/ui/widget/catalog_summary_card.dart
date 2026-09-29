import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'package:host_app/src/core/navigation/route_screen.dart';
import 'package:host_app/src/modules/home/ui/widget/summary_card.dart';
import 'package:host_app/src/modules/plant/model/plant_catalog.dart';
import 'package:host_app/src/modules/plant/viewmodel/plant_catalog_viewmodel.dart';
import 'package:host_app/src/shared/shared.dart';

class CatalogSummaryCard extends StatelessWidget {
  const CatalogSummaryCard({super.key});

  @override
  Widget build(BuildContext context) =>
      ReactiveAsyncBuilder<PlantCatalogViewModel, PlantCatalog>(
        notifier: PlantService.notifier,
        onLoading: () => const SizedBox.shrink(),
        onError: (_, _) => const SizedBox.shrink(),
        onData: (catalog, _, keep) => SummaryCard(
          icon: Icons.local_florist_outlined,
          title: HomeStrings.catalog,
          value: PlantStrings.catalogCount(
            catalog.plants.length,
            catalog.personCount,
          ),
          onTap: () => context.go(RouteScreen.plants.path),
        ),
      );
}
