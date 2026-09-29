import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:host_app/src/core/navigation/route_screen.dart';
import 'package:host_app/src/modules/plant/model/plant_catalog.dart';
import 'package:host_app/src/modules/plant/ui/widget/plant_list.dart';
import 'package:host_app/src/modules/plant/viewmodel/plant_catalog_viewmodel.dart';
import 'package:host_app/src/shared/shared.dart';

/// The list; a plant opens on its own page.
class PlantCatalogMobileView extends StatelessWidget {
  const PlantCatalogMobileView({
    super.key,
    required this.catalog,
    required this.viewModel,
  });

  final PlantCatalog catalog;

  final PlantCatalogViewModel viewModel;

  @override
  Widget build(BuildContext context) => BotanicaPage(
    title: PlantStrings.title,
    children: [
      PlantList(
        catalog: catalog,
        viewModel: viewModel,
        onOpen: (plant) =>
            context.push(RouteScreen.plantDetail.pathFor(plant.id)),
      ),
    ],
  );
}
