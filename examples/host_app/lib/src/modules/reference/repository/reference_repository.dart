import 'package:result_controller/result_controller.dart';

import 'package:host_app/src/core/network/api_failure.dart';

import 'package:host_app/src/core/network/api_envelope.dart';
import 'package:host_app/src/core/network/api_impl.dart';
import 'package:host_app/src/core/services/infra_service.dart';
import 'package:host_app/src/modules/reference/model/reference_data.dart';

class ReferenceRepository {
  const ReferenceRepository();

  ApiImpl get _api => InfraService.mainApi.notifier;

  Future<Result<ReferenceData, ApiFailure>> fetch() async =>
      (await _api.get(Params(path: '/reference/current')))
          .entity(ReferenceData.fromJson);
}
