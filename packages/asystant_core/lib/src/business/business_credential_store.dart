import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/business/business_credential_scope.dart';
import 'package:asystant_core/src/business/business_failure.dart';
import 'package:asystant_core/src/business/business_session_value.dart';

/// Where the host keeps what must never leave the device: each scope's
/// credential, its session values, the email it last signed in with and
/// the values of its private headers.
///
/// Implement it over the platform's secure storage (`asystant_ai` ships
/// `SecureCredentialStore`). A failed read or write is an `Err` with
/// `BusinessFailureCode.storage`, never an exception.
abstract interface class BusinessCredentialStore {
  /// The saved token or API key, or null when there is none.
  Future<Result<String?, BusinessFailure>> readCredential(
    BusinessCredentialScope scope,
  );

  Future<Result<void, BusinessFailure>> writeCredential(
    BusinessCredentialScope scope,
    String credential,
  );

  Future<Result<String?, BusinessFailure>> readSessionValue(
    BusinessCredentialScope scope,
    BusinessSessionValue value,
  );

  Future<Result<void, BusinessFailure>> writeSessionValue(
    BusinessCredentialScope scope,
    BusinessSessionValue value,
    String content,
  );

  /// Forgets the credential and every [BusinessSessionValue]; keeps the
  /// last email and the private headers.
  Future<Result<void, BusinessFailure>> clearSession(
    BusinessCredentialScope scope,
  );

  /// The email the scope last signed in with, to pre-fill the next sign-in.
  Future<Result<String?, BusinessFailure>> readLastEmail(
    BusinessCredentialScope scope,
  );

  Future<Result<void, BusinessFailure>> writeLastEmail(
    BusinessCredentialScope scope,
    String email,
  );

  /// The value of the private header [name] (case-insensitive), or null.
  Future<Result<String?, BusinessFailure>> readPrivateHeader(
    BusinessCredentialScope scope,
    String name,
  );

  Future<Result<void, BusinessFailure>> writePrivateHeader(
    BusinessCredentialScope scope,
    String name,
    String value,
  );

  Future<Result<void, BusinessFailure>> deletePrivateHeader(
    BusinessCredentialScope scope,
    String name,
  );
}
