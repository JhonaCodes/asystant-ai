import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:asystant_core/asystant_core.dart';

/// [BusinessCredentialStore] over the platform's secure storage (Keychain,
/// Keystore, ...). Every value is keyed by account, business, environment
/// and profile under [prefix].
///
/// Keys read `<prefix>.<account>.<business>.<env>.<field>` for the default
/// profile and `<prefix>.<account>.<business>.<env>.profile.<id>.<field>`
/// for a declared one, with `credential`, `refresh`, `session_id`,
/// `last_email` and `header.<name>` as fields. An app that already kept
/// business sessions with that layout keeps them by passing its prefix.
class SecureCredentialStore implements BusinessCredentialStore {
  const SecureCredentialStore({
    this.prefix = 'asystant_ai.business',
    FlutterSecureStorage storage = const FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
      ),
    ),
  }) : _storage = storage;

  /// The first segment of every key.
  final String prefix;

  final FlutterSecureStorage _storage;

  static final RegExp _forbiddenValue = RegExp('[\r\n]');

  @override
  Future<Result<String?, BusinessFailure>> readCredential(
    BusinessCredentialScope scope,
  ) => _read(_key(scope, 'credential'));

  @override
  Future<Result<void, BusinessFailure>> writeCredential(
    BusinessCredentialScope scope,
    String credential,
  ) => credential.trim().isEmpty
      ? _invalid('The credential is empty.')
      : _write(_key(scope, 'credential'), credential);

  @override
  Future<Result<String?, BusinessFailure>> readSessionValue(
    BusinessCredentialScope scope,
    BusinessSessionValue value,
  ) => _read(_key(scope, _sessionField(value)));

  @override
  Future<Result<void, BusinessFailure>> writeSessionValue(
    BusinessCredentialScope scope,
    BusinessSessionValue value,
    String content,
  ) => _write(_key(scope, _sessionField(value)), content);

  @override
  Future<Result<void, BusinessFailure>> clearSession(
    BusinessCredentialScope scope,
  ) async {
    for (final field in [
      'credential',
      for (final value in BusinessSessionValue.values) _sessionField(value),
    ]) {
      final deleted = await _delete(_key(scope, field));
      if (deleted.errorOrNull case final failure?) return Err(failure);
    }
    return Ok(null);
  }

  @override
  Future<Result<String?, BusinessFailure>> readLastEmail(
    BusinessCredentialScope scope,
  ) => _read(_key(scope, 'last_email'));

  @override
  Future<Result<void, BusinessFailure>> writeLastEmail(
    BusinessCredentialScope scope,
    String email,
  ) => _write(_key(scope, 'last_email'), email.trim());

  @override
  Future<Result<String?, BusinessFailure>> readPrivateHeader(
    BusinessCredentialScope scope,
    String name,
  ) => _read(_headerKey(scope, name));

  @override
  Future<Result<void, BusinessFailure>> writePrivateHeader(
    BusinessCredentialScope scope,
    String name,
    String value,
  ) {
    if (!name.isBusinessHeaderName) {
      return _invalid('Invalid or reserved header name $name.');
    }
    if (value.isEmpty || _forbiddenValue.hasMatch(value)) {
      return _invalid('The value of $name must be a single line.');
    }
    return _write(_headerKey(scope, name), value);
  }

  @override
  Future<Result<void, BusinessFailure>> deletePrivateHeader(
    BusinessCredentialScope scope,
    String name,
  ) => _delete(_headerKey(scope, name));

  String _key(BusinessCredentialScope scope, String field) => [
    prefix,
    scope.accountId,
    scope.businessId,
    scope.environment.name,
    if (!scope.isDefaultProfile) ...['profile', scope.profile],
    field,
  ].join('.');

  String _headerKey(BusinessCredentialScope scope, String name) =>
      _key(scope, 'header.${name.toLowerCase()}');

  static String _sessionField(BusinessSessionValue value) => switch (value) {
    .refreshToken => 'refresh',
    .sessionId => 'session_id',
  };

  Future<Result<String?, BusinessFailure>> _read(String key) async {
    try {
      return Ok(await _storage.read(key: key));
    } on PlatformException catch (error) {
      return Err(_storageFailure('read', error));
    }
  }

  Future<Result<void, BusinessFailure>> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      return Ok(null);
    } on PlatformException catch (error) {
      return Err(_storageFailure('write', error));
    }
  }

  Future<Result<void, BusinessFailure>> _delete(String key) async {
    try {
      await _storage.delete(key: key);
      return Ok(null);
    } on PlatformException catch (error) {
      return Err(_storageFailure('delete', error));
    }
  }

  static Future<Result<void, BusinessFailure>> _invalid(String message) async =>
      Err(BusinessFailure(.invalidInput, message: message));

  /// Names the operation and the platform code, never the key or value.
  static BusinessFailure _storageFailure(
    String operation,
    PlatformException error,
  ) => BusinessFailure(
    .storage,
    message: 'The device vault could not $operation a value (${error.code}).',
  );
}
