/// Recognizes the names of values that must never reach the model.
extension BusinessSecretName on String {
  static const List<String> _fragments = [
    'password',
    'secret',
    'token',
    'apikey',
    'rawkey',
    'companykey',
    'privatekey',
    'authorization',
    'credential',
    'totp',
    'recoverycode',
    'verificationcode',
  ];

  static const Set<String> _names = {'key', 'otp', 'code', 'pin'};

  /// This name without case, spaces, dashes or underscores: `Api-Key` and
  /// `api_key` are both `apikey`.
  String get normalizedBusinessName =>
      toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

  /// Whether a JSON member or header named like this carries a secret, such
  /// as `password`, `access_token`, `X-Api-Key` or `code`.
  bool get isBusinessSecretName {
    final normalized = normalizedBusinessName;
    return _fragments.any(normalized.contains) || _names.contains(normalized);
  }
}
