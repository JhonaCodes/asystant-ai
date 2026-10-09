import 'package:asystant_core/src/business/business_secret_name.dart';

/// Keeps credentials out of what an assistant reads.
extension BusinessRedaction on Object? {
  static final RegExp _tokenLike = RegExp(
    r'bearer\s+\S+|-----BEGIN [A-Z ]+-----|\beyJ[A-Za-z0-9_-]{20,}\.',
    caseSensitive: false,
  );

  static final RegExp _longOpaque = RegExp(r'^[A-Za-z0-9_\-]{48,}$');

  static final RegExp _credentialInText = RegExp(
    r'\bBearer\s+[A-Za-z0-9._~-]{20,}|-----BEGIN [A-Z ]+PRIVATE KEY-----',
    caseSensitive: false,
  );

  static const Set<String> _credentialMembers = {
    'credential',
    'password',
    'secret',
    'token',
    'api_key',
    'apikey',
    'totp',
    'otp',
  };

  /// This JSON value with every secret replaced by `[redacted]`: members
  /// with a secret name (`BusinessSecretName`), strings that contain one of
  /// [privateValues], and strings that look like a token or a key.
  Object? toRedacted(Iterable<String> privateValues) {
    final value = this;
    return switch (value) {
      final String text =>
        privateValues.any(
                  (secret) => secret.isNotEmpty && text.contains(secret),
                ) ||
                _tokenLike.hasMatch(text) ||
                _longOpaque.hasMatch(text)
            ? '[redacted]'
            : text,
      final List<Object?> list => [
        for (final entry in list) entry.toRedacted(privateValues),
      ],
      final Map<Object?, Object?> map => <String, Object?>{
        for (final entry in map.entries)
          '${entry.key}': '${entry.key}'.isBusinessSecretName
              ? '[redacted]'
              : entry.value.toRedacted(privateValues),
      },
      _ => value,
    };
  }

  /// Whether this JSON value carries a credential: a member named like one
  /// (`password`, `token`, `api_key`, ...) or a Bearer token or private key
  /// in a string. A contract that does is rejected before it is saved.
  bool get containsBusinessCredential {
    final value = this;
    return switch (value) {
      final String text => _credentialInText.hasMatch(text),
      final List<Object?> list => list.any(
        (entry) => entry.containsBusinessCredential,
      ),
      final Map<Object?, Object?> map => map.entries.any(
        (entry) =>
            _credentialMembers.contains('${entry.key}'.toLowerCase()) ||
            entry.value.containsBusinessCredential,
      ),
      _ => false,
    };
  }
}
