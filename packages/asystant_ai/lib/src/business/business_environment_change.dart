import 'package:asystant_core/asystant_core.dart';

/// One decoded call of `ConfigureBusinessEnvironmentTool`: the address
/// and/or the API key or Bearer token the person gave for one environment.
/// Transient tool input, never serialized, so it has no JSON form.
class BusinessEnvironmentChange {
  const BusinessEnvironmentChange({
    required this.business,
    required this.environment,
    this.profile,
    this.baseUrl,
    this.scheme,
    this.apiKeyHeader,
    this.credential,
  });

  final BusinessContract business;
  final BusinessEnvironment environment;
  final String? profile;
  final String? baseUrl;
  final BusinessAuthScheme? scheme;
  final String? apiKeyHeader;

  /// The key or token, already resolved from the chat's private reference.
  final String? credential;

  BusinessEnvironmentChange copyWith({
    BusinessContract? business,
    BusinessEnvironment? environment,
    String? profile,
    String? baseUrl,
    BusinessAuthScheme? scheme,
    String? apiKeyHeader,
    String? credential,
  }) => BusinessEnvironmentChange(
    business: business ?? this.business,
    environment: environment ?? this.environment,
    profile: profile ?? this.profile,
    baseUrl: baseUrl ?? this.baseUrl,
    scheme: scheme ?? this.scheme,
    apiKeyHeader: apiKeyHeader ?? this.apiKeyHeader,
    credential: credential ?? this.credential,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessEnvironmentChange &&
          business == other.business &&
          environment == other.environment &&
          profile == other.profile &&
          baseUrl == other.baseUrl &&
          scheme == other.scheme &&
          apiKeyHeader == other.apiKeyHeader &&
          credential == other.credential;

  @override
  int get hashCode => Object.hash(
    business,
    environment,
    profile,
    baseUrl,
    scheme,
    apiKeyHeader,
    credential,
  );
}
