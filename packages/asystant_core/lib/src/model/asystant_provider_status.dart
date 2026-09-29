import 'package:asystant_core/src/model/assistant_value.dart';

/// What a model provider reported when asked whether it can answer, without
/// running an inference.
///
/// The same shape for every provider, so a settings screen's "Test
/// connection" does not depend on which one is configured. A provider that
/// cannot be reached at all (a missing binary, a refused key, no network)
/// reports an `Err` instead; see `AssistantTransport.verify`.
class AsystantProviderStatus extends AssistantValue {
  const AsystantProviderStatus({
    required this.provider,
    this.signedIn,
    this.version = '',
    this.account = '',
  });

  /// The provider's name as a person reads it, e.g. "Claude Code".
  final String provider;

  /// Whether the provider accepts requests from this app now; null when it
  /// cannot tell, as with an older CLI that has no status command.
  final bool? signedIn;

  /// Version of the local program that answers; empty for a remote API.
  final String version;

  /// A non-secret description of the account, e.g. "claude.ai · max";
  /// empty when there is nothing to show. Never a key or an email address.
  final String account;

  /// Whether an inference can be expected to work: not known to be signed
  /// out.
  bool get isReady => signedIn != false;

  AsystantProviderStatus copyWith({
    String? provider,
    bool? signedIn,
    String? version,
    String? account,
  }) => AsystantProviderStatus(
    provider: provider ?? this.provider,
    signedIn: signedIn ?? this.signedIn,
    version: version ?? this.version,
    account: account ?? this.account,
  );

  factory AsystantProviderStatus.fromJson(Map<String, Object?> json) =>
      AsystantProviderStatus(
        provider: json['provider'] as String,
        signedIn: json['signed_in'] as bool?,
        version: json['version'] as String? ?? '',
        account: json['account'] as String? ?? '',
      );

  @override
  Map<String, Object?> toJson() => {
    'provider': provider,
    'signed_in': signedIn,
    'version': version,
    'account': account,
  };

  @override
  String toString() =>
      'AsystantProviderStatus($provider, signedIn: $signedIn, '
      'version: $version)';
}
