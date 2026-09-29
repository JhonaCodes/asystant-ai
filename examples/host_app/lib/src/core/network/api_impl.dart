import 'package:result_controller/result_controller.dart';

import 'package:host_app/src/core/network/api_failure.dart';

/// The app's backend, as repositories see it: REST-like paths and JSON.
///
/// Every successful response is an envelope `{"data": ...}`. Errors are
/// [ApiFailure] with a stable `title` (`not_found`, `bad_request`,
/// `method_not_allowed`, `storage_unavailable`) and the status code on the
/// [ApiResult].
///
/// Today [LocalApi] answers from the device. A remote backend implements
/// this same interface and is plugged in at `InfraService.mainApi`; nothing
/// else changes.
abstract interface class ApiImpl {
  /// Prepares the backend (open the database, sign in, ...). Safe to repeat.
  Future<Result<bool, ApiFailure>> open();

  Future<ApiResult<Map<String, Object?>>> get(Params<Object?> params);

  Future<ApiResult<Map<String, Object?>>> post(Params<Object?> params);

  /// Creates or replaces the resource at the path.
  Future<ApiResult<Map<String, Object?>>> put(Params<Object?> params);

  /// Merges the body's top-level fields into the resource.
  Future<ApiResult<Map<String, Object?>>> patch(Params<Object?> params);

  Future<ApiResult<Map<String, Object?>>> delete(Params<Object?> params);
}
