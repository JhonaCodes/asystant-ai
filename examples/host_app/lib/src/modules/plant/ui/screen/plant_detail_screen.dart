import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'package:host_app/src/modules/plant/model/plant.dart';
import 'package:host_app/src/modules/plant/model/plant_catalog.dart';
import 'package:host_app/src/modules/plant/ui/view/plant_detail_view.dart';
import 'package:host_app/src/modules/plant/viewmodel/plant_catalog_viewmodel.dart';
import 'package:host_app/src/shared/shared.dart';

/// One plant on its own page (phones).
class PlantDetailScreen extends StatelessWidget {
  const PlantDetailScreen({super.key, required this.plantId});

  final String plantId;

  @override
  Widget build(
    BuildContext context,
  ) => ReactiveAsyncBuilder<PlantCatalogViewModel, PlantCatalog>(
    notifier: PlantService.notifier,
    onLoading: () => const BotanicaPage(
      title: PlantStrings.title,
      showsBack: true,
      children: [LoadingView()],
    ),
    onError: (_, _) => BotanicaPage(
      title: PlantStrings.title,
      showsBack: true,
      children: [ErrorView(onRetry: PlantService.notifier.reload)],
    ),
    onData: (catalog, viewModel, keep) => switch (catalog.byId(plantId)) {
      final plant? => BotanicaPage(
        title: plant.commonName,
        showsBack: true,
        actions: [
          if (!plant.isSeed)
            _DeletePlantAction(plant: plant, viewModel: viewModel),
        ],
        children: [PlantDetailView(plant: plant, labelOf: viewModel.labelOf)],
      ),
      null => const BotanicaPage(
        title: PlantStrings.title,
        showsBack: true,
        children: [
          EmptyState(icon: Icons.search_off, message: CommonStrings.notFound),
        ],
      ),
    },
  );
}

class _DeletePlantAction extends StatelessWidget {
  const _DeletePlantAction({required this.plant, required this.viewModel});

  final Plant plant;

  final PlantCatalogViewModel viewModel;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await ConfirmDialog.ask(
      context,
      title: PlantStrings.deleteTitle,
      body: PlantStrings.deleteBody,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final deleted = await viewModel.deletePersonPlant(plant.id);
    if (deleted.isOk && context.mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: PlantStrings.deletePlant,
    icon: const Icon(Icons.delete_outline),
    onPressed: () => _delete(context),
  );
}
