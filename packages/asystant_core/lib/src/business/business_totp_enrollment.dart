/// A new authenticator the API asks the person to add during sign-in: the
/// `otpauth://` [uri] to show as a QR and the manual [secret].
///
/// Transient: it is shown once and never serialized, so it has no JSON
/// form. The host never gives it to the model.
class BusinessTotpEnrollment {
  const BusinessTotpEnrollment({required this.uri, this.secret = ''});

  final String uri;

  /// The key to type by hand; empty when the API did not send one.
  final String secret;

  BusinessTotpEnrollment copyWith({String? uri, String? secret}) =>
      BusinessTotpEnrollment(
        uri: uri ?? this.uri,
        secret: secret ?? this.secret,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessTotpEnrollment &&
          uri == other.uri &&
          secret == other.secret;

  @override
  int get hashCode => Object.hash(uri, secret);
}
