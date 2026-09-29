import 'dart:typed_data';

import 'package:logger_rs/logger_rs.dart';
import 'package:reactive_notifier/reactive_notifier.dart';
import 'package:result_controller/result_controller.dart';

import 'package:host_app/src/core/network/api_failure.dart';

import 'package:host_app/src/core/network/file_transfer.dart';
import 'package:host_app/src/core/services/loaded_state.dart';
import 'package:host_app/src/core/network/file_upload.dart';
import 'package:host_app/src/modules/plant/model/plant.dart';
import 'package:host_app/src/modules/plant/model/plant_catalog.dart';
import 'package:host_app/src/modules/plant/model/plant_enums.dart';
import 'package:host_app/src/modules/plant/model/plant_media.dart';
import 'package:host_app/src/modules/plant/repository/plant_repository.dart';
import 'package:host_app/src/modules/reference/viewmodel/reference_viewmodel.dart';
import 'package:host_app/src/shared/shared.dart';

/// The plant catalog: the bundled plants and the ones the person added.
///
/// Bundled plants are read-only. The public methods are what the assistant's
/// tools call in the next phase.
class PlantCatalogViewModel extends AsyncViewModelImpl<PlantCatalog>
    with LoadedState<PlantCatalog> {
  PlantCatalogViewModel() : super(AsyncState.initial());

  PlantRepository get _repository => const PlantRepository();

  FileTransfer get _files => const FileTransfer();

  static final _slug = RegExp(r'[^a-z0-9]+');

  @override
  Future<PlantCatalog> init() async {
    final loaded = await _repository.fetchAll();
    return loaded.when(
      ok: (plants) => PlantCatalog(plants: _sorted(plants)),
      err: (failure) => throw failure,
    );
  }

  PlantCatalog get _current =>
      hasData ? data ?? const PlantCatalog() : const PlantCatalog();

  void select(String? id) => updateState(
    _current.copyWith(selectedId: id, clearSelection: id == null),
  );

  void search(String query) => updateState(_current.copyWith(query: query));

  void showOrigin(PlantOriginFilter filter) =>
      updateState(_current.copyWith(filter: filter));

  /// The readable name of a vocabulary tag (condition, medicine, allergen).
  String labelOf(String tag) => ReferenceService.notifier.labelOf(tag);

  /// Plants whose names contain [query], accent-insensitive.
  List<Plant> findByName(String query) =>
      _current.copyWith(query: query, filter: PlantOriginFilter.all).visible;

  /// Saves a plant the person described; its id comes from its name.
  Future<Result<Plant, ApiFailure>> addPersonPlant(Plant draft) async {
    // The id is checked against the whole catalog, never an empty one.
    if (await _notReady() case final ApiFailure failure) {
      return Err(failure);
    }
    final plant = draft.copyWith(
      id: _uniqueId(draft.commonName),
      origin: PlantOrigin.person,
    );
    final created = await _repository.create(plant);
    return created.when(
      ok: (saved) {
        _put(saved);
        return Ok(saved);
      },
      err: _logged,
    );
  }

  Future<Result<Plant, ApiFailure>> updatePersonPlant(Plant plant) async {
    if (await _notReady() case final ApiFailure failure) {
      return Err(failure);
    }
    if (_current.byId(plant.id)?.origin != PlantOrigin.person) {
      return _readOnly;
    }
    final replaced = await _repository.replace(
      plant.copyWith(origin: PlantOrigin.person),
    );
    return replaced.when(
      ok: (saved) {
        _put(saved);
        return Ok(saved);
      },
      err: _logged,
    );
  }

  /// Stores a photo of a plant the person added.
  Future<Result<Plant, ApiFailure>> attachPhoto(
    String plantId, {
    required Uint8List bytes,
    required String filename,
    String mimeType = 'image/jpeg',
    String caption = '',
  }) async {
    if (await _notReady() case final ApiFailure failure) {
      return Err(failure);
    }
    final plant = _current.byId(plantId);
    if (plant == null || plant.origin != PlantOrigin.person) {
      return _readOnly;
    }
    final uploaded = await _files.upload(
      FileUpload(bytes: bytes, filename: filename, mimeType: mimeType),
    );
    final file = uploaded.when(ok: (file) => file, err: (_) => null);
    if (file == null) {
      return Err(uploaded.errorOrNull ?? _unavailable);
    }
    final updated = await updatePersonPlant(
      plant.copyWith(
        photos: [
          ...plant.photos,
          PlantPhoto(ref: file.ref, fileId: file.id, caption: caption),
        ],
      ),
    );
    if (updated.isErr) {
      // The record did not take the photo; do not leave the file behind.
      await _files.remove(file.id);
    }
    return updated;
  }

  Future<Result<Plant, ApiFailure>> removePhoto(
    String plantId,
    String ref,
  ) async {
    if (await _notReady() case final ApiFailure failure) {
      return Err(failure);
    }
    final plant = _current.byId(plantId);
    if (plant == null || plant.origin != PlantOrigin.person) {
      return _readOnly;
    }
    final photo = plant.photos.where((item) => item.ref == ref).firstOrNull;
    final updated = await updatePersonPlant(
      plant.copyWith(
        photos: plant.photos.where((item) => item.ref != ref).toList(),
      ),
    );
    if (updated.isOk && photo != null && photo.fileId.isNotEmpty) {
      await _files.remove(photo.fileId);
    }
    return updated;
  }

  Future<Result<bool, ApiFailure>> deletePersonPlant(String plantId) async {
    if (await _notReady() case final ApiFailure failure) {
      return Err(failure);
    }
    final plant = _current.byId(plantId);
    if (plant == null || plant.origin != PlantOrigin.person) {
      return Err(_readOnlyError);
    }
    final removed = await _repository.remove(plantId);
    return removed.when(
      ok: (_) async {
        for (final photo in plant.photos.where(
          (item) => item.fileId.isNotEmpty,
        )) {
          await _files.remove(photo.fileId);
        }
        updateState(
          _current.copyWith(
            plants: _current.plants
                .where((item) => item.id != plantId)
                .toList(),
            clearSelection: _current.selectedId == plantId,
          ),
        );
        return Ok(true);
      },
      err: (failure) async {
        Log.w('Deleting plant $plantId failed: ${failure.msm}');
        return Err(failure);
      },
    );
  }

  /// Null once the catalog is loaded; the failure when it cannot load.
  Future<ApiFailure?> _notReady() async =>
      await loaded() == null ? AppFailures.notReady('The plant catalog') : null;

  void _put(Plant plant) => updateState(
    _current.copyWith(
      plants: _sorted([
        ..._current.plants.where((item) => item.id != plant.id),
        plant,
      ]),
    ),
  );

  String _uniqueId(String name) {
    final base = name.searchKey
        .replaceAll(_slug, '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final stem = base.isEmpty
        ? 'planta'
        : base.substring(0, base.length.clamp(0, 48));
    var candidate = stem;
    for (var index = 2; _current.byId(candidate) != null; index++) {
      candidate = '${stem}_$index';
    }
    return candidate;
  }

  static List<Plant> _sorted(List<Plant> plants) => [...plants]
    ..sort((a, b) => a.commonName.searchKey.compareTo(b.commonName.searchKey));

  static Result<Plant, ApiFailure> _logged(ApiFailure failure) {
    Log.w('Plant change failed: ${failure.title} ${failure.msm}');
    return Err(failure);
  }

  static final ApiFailure _readOnlyError = ApiErr(
    title: 'seed_read_only',
    msm: 'Bundled plants cannot be changed.',
  );

  static Result<Plant, ApiFailure> get _readOnly => Err(_readOnlyError);

  static final ApiFailure _unavailable = ApiErr(
    title: 'storage_unavailable',
    msm: 'The photo could not be stored.',
  );
}

mixin PlantService {
  static final ReactiveNotifier<PlantCatalogViewModel> catalog =
      ReactiveNotifier<PlantCatalogViewModel>(PlantCatalogViewModel.new);

  static PlantCatalogViewModel get notifier => catalog.notifier;
}
