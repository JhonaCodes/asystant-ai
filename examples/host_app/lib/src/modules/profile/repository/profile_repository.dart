import 'package:result_controller/result_controller.dart';

import 'package:host_app/src/core/network/api_failure.dart';

import 'package:host_app/src/core/network/api_envelope.dart';
import 'package:host_app/src/core/network/api_impl.dart';
import 'package:host_app/src/core/services/infra_service.dart';
import 'package:host_app/src/modules/profile/model/person_profile.dart';

/// The person's profile, one per install.
class ProfileRepository {
  const ProfileRepository();

  static const _path = '/profile/me';

  ApiImpl get _api => InfraService.mainApi.notifier;

  /// The saved profile, or [PersonProfile.empty] when none exists yet.
  Future<Result<PersonProfile, ApiFailure>> fetch() async {
    final response = await _api.get(Params(path: _path));
    return response.statusCode == 404
        ? Ok(PersonProfile.empty)
        : response.entity(PersonProfile.fromJson);
  }

  Future<Result<PersonProfile, ApiFailure>> save(PersonProfile profile) async =>
      (await _api.put(Params(path: _path, body: profile.toJson())))
          .entity(PersonProfile.fromJson);

  Future<Result<bool, ApiFailure>> remove() async =>
      (await _api.delete(Params(path: _path))).done();
}
