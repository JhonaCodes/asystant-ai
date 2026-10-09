import 'package:collection/collection.dart';

import 'package:asystant_core/src/business/business_auth_flow.dart';
import 'package:asystant_core/src/business/business_credential_profile.dart';
import 'package:asystant_core/src/business/business_json_reading.dart';

/// One environment of a business API: its address, how it signs in
/// ([auth]), the headers every operation carries and the credential
/// [profiles] it can be operated with.
class BusinessEndpoint {
  const BusinessEndpoint({
    required this.baseUrl,
    this.auth = const BusinessAuthFlow(),
    this.headers = const {},
    this.privateHeaders = const [],
    this.profiles = const [],
  });

  /// Address the operation paths are appended to, such as
  /// `https://api.example.com/v1`.
  final String baseUrl;

  final BusinessAuthFlow auth;

  /// Public headers sent with every operation and sign-in request.
  final Map<String, String> headers;

  /// Names of headers whose values live in the device vault.
  final List<String> privateHeaders;

  /// The identities declared for this environment; empty means a single
  /// default one ([BusinessCredentialProfile.fallback]).
  final List<BusinessCredentialProfile> profiles;

  /// [profiles], or the single default profile when none is declared. The
  /// first one is used when a call does not name a profile.
  List<BusinessCredentialProfile> get credentialProfiles =>
      profiles.isEmpty ? const [BusinessCredentialProfile.fallback] : profiles;

  /// The profile [id] of [credentialProfiles], if declared.
  BusinessCredentialProfile? profile(String id) =>
      credentialProfiles.firstWhereOrNull((profile) => profile.id == id);

  /// Reads both contract formats: the current one, whose sign-in is an
  /// `auth` object ([BusinessAuthFlow.fromJson]), and the first one, whose
  /// `auth_kind` and flat sign-in members are read by
  /// [BusinessAuthFlow.fromLegacyJson] with [businessId].
  factory BusinessEndpoint.fromJson(
    Map<String, Object?> json, {
    String businessId = '',
  }) => BusinessEndpoint(
    baseUrl: json.requiredString('base_url'),
    auth: switch (json.optionalObject('auth')) {
      final Map<String, Object?> auth => BusinessAuthFlow.fromJson(auth),
      null when json.containsKey('auth_kind') =>
        BusinessAuthFlow.fromLegacyJson(json, businessId: businessId),
      null => const BusinessAuthFlow(),
    },
    headers: json.stringMap('headers'),
    privateHeaders: json.stringList('private_headers'),
    profiles: [
      for (final profile in json.objectList('profiles'))
        BusinessCredentialProfile.fromJson(profile),
    ],
  );

  Map<String, Object?> toJson() => {
    'base_url': baseUrl,
    'auth': auth.toJson(),
    if (headers.isNotEmpty) 'headers': headers,
    if (privateHeaders.isNotEmpty) 'private_headers': privateHeaders,
    if (profiles.isNotEmpty)
      'profiles': profiles.map((profile) => profile.toJson()).toList(),
  };

  BusinessEndpoint copyWith({
    String? baseUrl,
    BusinessAuthFlow? auth,
    Map<String, String>? headers,
    List<String>? privateHeaders,
    List<BusinessCredentialProfile>? profiles,
  }) => BusinessEndpoint(
    baseUrl: baseUrl ?? this.baseUrl,
    auth: auth ?? this.auth,
    headers: headers ?? this.headers,
    privateHeaders: privateHeaders ?? this.privateHeaders,
    profiles: profiles ?? this.profiles,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessEndpoint &&
          baseUrl == other.baseUrl &&
          auth == other.auth &&
          const MapEquality<String, String>().equals(headers, other.headers) &&
          const UnorderedIterableEquality<String>().equals(
            privateHeaders,
            other.privateHeaders,
          ) &&
          const ListEquality<BusinessCredentialProfile>().equals(
            profiles,
            other.profiles,
          );

  @override
  int get hashCode => Object.hash(
    baseUrl,
    auth,
    const MapEquality<String, String>().hash(headers),
    const UnorderedIterableEquality<String>().hash(privateHeaders),
    Object.hashAll(profiles),
  );
}
