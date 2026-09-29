import 'package:reactive_notifier/reactive_notifier.dart';
import 'package:result_controller/result_controller.dart';

import 'package:host_app/src/core/network/api_failure.dart';

import 'package:host_app/src/core/network/api_impl.dart';
import 'package:host_app/src/core/network/local/local_api.dart';

/// The app's backend.
///
/// To move from the device to a server, replace `LocalApi.new` with a remote
/// implementation of [ApiImpl] (same paths, same `{"data": ...}` envelope).
/// Repositories, view models and screens stay as they are.
mixin InfraService {
  static final ReactiveNotifier<ApiImpl> mainApi = ReactiveNotifier<ApiImpl>(
    LocalApi.new,
  );

  static Future<Result<bool, ApiFailure>> open() => mainApi.notifier.open();
}
