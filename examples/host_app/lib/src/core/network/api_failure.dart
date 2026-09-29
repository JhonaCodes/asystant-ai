import 'package:result_controller/result_controller.dart';

/// The failure every repository returns: an [ApiErr] whose `title` is a
/// stable code (`not_found`, `bad_request`, `storage_unavailable`, ...).
typedef ApiFailure = ApiErr<Object?>;

/// Failures raised by the app itself rather than by the backend.
abstract final class AppFailures {
  /// The data a change builds on has not loaded (or failed to load).
  static ApiFailure notReady(String what) =>
      ApiErr(title: 'not_ready', msm: '$what is not loaded yet.');
}
