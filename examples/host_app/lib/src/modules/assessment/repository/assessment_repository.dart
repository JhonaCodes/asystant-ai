import 'package:result_controller/result_controller.dart';

import 'package:host_app/src/core/network/api_failure.dart';

import 'package:host_app/src/core/network/api_envelope.dart';
import 'package:host_app/src/core/network/api_impl.dart';
import 'package:host_app/src/core/services/infra_service.dart';
import 'package:host_app/src/modules/assessment/model/assessment.dart';

class AssessmentRepository {
  const AssessmentRepository();

  static const _path = '/assessments';

  ApiImpl get _api => InfraService.mainApi.notifier;

  Future<Result<List<Assessment>, ApiFailure>> fetchAll() async =>
      (await _api.get(Params(path: _path))).list(Assessment.fromJson);

  Future<Result<Assessment, ApiFailure>> fetch(String id) async =>
      (await _api.get(Params(path: '$_path/$id'))).entity(Assessment.fromJson);

  /// Creates it; the backend assigns the id.
  Future<Result<Assessment, ApiFailure>> create({
    required String reason,
  }) async =>
      (await _api.post(Params(path: _path, body: {'reason': reason})))
          .entity(Assessment.fromJson);

  Future<Result<Assessment, ApiFailure>> replace(Assessment assessment) async =>
      (await _api.put(
        Params(path: '$_path/${assessment.id}', body: assessment.toJson()),
      )).entity(Assessment.fromJson);

  Future<Result<bool, ApiFailure>> remove(String id) async =>
      (await _api.delete(Params(path: '$_path/$id'))).done();
}
