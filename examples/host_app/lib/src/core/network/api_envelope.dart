import 'package:result_controller/result_controller.dart';

import 'package:host_app/src/core/network/api_failure.dart';

/// Reads the `{"data": ...}` envelope of an API response into models.
///
/// A body that does not match the model becomes an `invalid_response`
/// error here, at the boundary, instead of an exception in a view model.
extension ApiEnvelope on ApiResult<Map<String, Object?>> {
  Result<T, ApiFailure> entity<T>(
    T Function(Map<String, Object?> json) fromJson,
  ) => when(
    ok: (body) => _parse(() => fromJson(body['data'] as Map<String, Object?>)),
    err: Err.new,
  );

  Result<List<T>, ApiFailure> list<T>(
    T Function(Map<String, Object?> json) fromJson,
  ) => when(
    ok: (body) => _parse(
      () => [
        for (final item in body['data'] as List<Object?>)
          fromJson(item as Map<String, Object?>),
      ],
    ),
    err: Err.new,
  );

  Result<bool, ApiFailure> done() => when(ok: (_) => Ok(true), err: Err.new);

  static Result<T, ApiFailure> _parse<T>(T Function() read) {
    try {
      return Ok(read());
    } on FormatException catch (error, stackTrace) {
      return Err(_invalid(error, stackTrace));
    } on TypeError catch (error, stackTrace) {
      return Err(_invalid(error, stackTrace));
    } on ArgumentError catch (error, stackTrace) {
      // An unknown enum name in the data.
      return Err(_invalid(error, stackTrace));
    }
  }

  static ApiFailure _invalid(Object error, StackTrace stackTrace) => ApiErr(
    title: 'invalid_response',
    msm: 'The response does not match the expected data.',
    exception: error,
    stackTrace: stackTrace,
  );
}
