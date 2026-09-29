import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'package:host_app/src/integrations/device/device.dart';
import 'package:host_app/src/modules/plant/model/plant_catalog.dart';
import 'package:host_app/src/modules/plant/ui/mobile/plant_catalog_mobile_view.dart';
import 'package:host_app/src/modules/plant/ui/tablet/plant_catalog_tablet_view.dart';
import 'package:host_app/src/modules/plant/viewmodel/plant_catalog_viewmodel.dart';
import 'package:host_app/src/shared/shared.dart';

class PlantCatalogScreen extends StatelessWidget {
  const PlantCatalogScreen({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => ReactiveAsyncBuilder<PlantCatalogViewModel, PlantCatalog>(
    notifier: PlantService.notifier,
    onLoading: () => const LoadingView(),
    onError: (_, _) => ErrorView(onRetry: PlantService.notifier.reload),
    onData: (catalog, viewModel, keep) => DeviceLayout(
      mobile: PlantCatalogMobileView(catalog: catalog, viewModel: viewModel),
      tablet: PlantCatalogTabletView(catalog: catalog, viewModel: viewModel),
    ),
  );
}
