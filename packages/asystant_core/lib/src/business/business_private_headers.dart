import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/business/business_credential_scope.dart';
import 'package:asystant_core/src/business/business_credential_store.dart';
import 'package:asystant_core/src/business/business_failure.dart';
import 'package:asystant_core/src/business/business_failure_code.dart';

/// Reads the private headers a request needs from a
/// [BusinessCredentialStore].
extension BusinessPrivateHeaders on BusinessCredentialStore {
  /// The saved value of every header in [names]; an `Err` with
  /// [BusinessFailureCode.missingPrivateHeader] naming the first one that
  /// has no value.
  Future<Result<Map<String, String>, BusinessFailure>> readPrivateHeaders(
    BusinessCredentialScope scope,
    Iterable<String> names,
  ) async {
    final values = <String, String>{};
    for (final name in names) {
      final read = await readPrivateHeader(scope, name);
      if (read.errorOrNull case final failure?) return Err(failure);
      final value = read.data;
      if (value == null || value.isEmpty) {
        return Err(
          BusinessFailure(
            .missingPrivateHeader,
            message: 'The private header $name has no value on this device.',
          ),
        );
      }
      values[name] = value;
    }
    return Ok(values);
  }

  /// The headers of [names] that have no saved value.
  Future<Result<List<String>, BusinessFailure>> missingPrivateHeaders(
    BusinessCredentialScope scope,
    Iterable<String> names,
  ) async {
    final missing = <String>[];
    for (final name in names) {
      final read = await readPrivateHeader(scope, name);
      if (read.errorOrNull case final failure?) return Err(failure);
      if (read.data?.isEmpty ?? true) missing.add(name);
    }
    return Ok(missing);
  }

  /// Whether [scope] has a saved, non-empty credential.
  Future<Result<bool, BusinessFailure>> hasSession(
    BusinessCredentialScope scope,
  ) async =>
      (await readCredential(scope))
          .map((credential) => credential?.isNotEmpty ?? false);
}
