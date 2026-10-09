import 'package:asystant_core/asystant_core.dart';

/// One decoded call of `ConfigureBusinessPrivateHeaderTool`: which declared
/// header, for which environment and profile, and its value when the model
/// passed one (already resolved from the chat's private reference).
/// Transient tool input, never serialized, so it has no JSON form.
class BusinessPrivateHeaderValue {
  const BusinessPrivateHeaderValue({
    required this.business,
    required this.environment,
    required this.header,
    this.profile,
    this.value,
  });

  final BusinessContract business;
  final BusinessEnvironment environment;
  final String header;
  final String? profile;
  final String? value;

  BusinessPrivateHeaderValue copyWith({
    BusinessContract? business,
    BusinessEnvironment? environment,
    String? header,
    String? profile,
    String? value,
  }) => BusinessPrivateHeaderValue(
    business: business ?? this.business,
    environment: environment ?? this.environment,
    header: header ?? this.header,
    profile: profile ?? this.profile,
    value: value ?? this.value,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessPrivateHeaderValue &&
          business == other.business &&
          environment == other.environment &&
          header == other.header &&
          profile == other.profile &&
          value == other.value;

  @override
  int get hashCode =>
      Object.hash(business, environment, header, profile, value);
}
