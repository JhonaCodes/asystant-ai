import 'package:result_controller/result_controller.dart';

import 'package:host_app/src/core/network/api_failure.dart';

import 'package:host_app/src/core/network/api_envelope.dart';
import 'package:host_app/src/core/network/api_impl.dart';
import 'package:host_app/src/core/services/infra_service.dart';
import 'package:host_app/src/modules/plant/model/plant.dart';

class PlantRepository {
  const PlantRepository();

  static const _path = '/plants';

  ApiImpl get _api => InfraService.mainApi.notifier;

  Future<Result<List<Plant>, ApiFailure>> fetchAll() async =>
      (await _api.get(Params(path: _path))).list(Plant.fromJson);

  Future<Result<Plant, ApiFailure>> fetch(String id) async =>
      (await _api.get(Params(path: '$_path/$id'))).entity(Plant.fromJson);

  Future<Result<Plant, ApiFailure>> create(Plant plant) async =>
      (await _api.post(Params(path: _path, body: plant.toJson())))
          .entity(Plant.fromJson);

  Future<Result<Plant, ApiFailure>> replace(Plant plant) async =>
      (await _api.put(Params(path: '$_path/${plant.id}', body: plant.toJson())))
          .entity(Plant.fromJson);

  Future<Result<bool, ApiFailure>> remove(String id) async =>
      (await _api.delete(Params(path: '$_path/$id'))).done();
}
