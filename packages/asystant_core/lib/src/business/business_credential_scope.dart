import 'package:asystant_core/src/business/business_credential_profile.dart';
import 'package:asystant_core/src/business/business_environment.dart';
import 'package:asystant_core/src/business/business_json_reading.dart';

/// Whose credential: one account of the host app, one business, one
/// environment and one credential profile. Every value a
/// `BusinessCredentialStore` keeps belongs to exactly one scope.
class BusinessCredentialScope {
  const BusinessCredentialScope({
    required this.accountId,
    required this.businessId,
    required this.environment,
    this.profile = BusinessCredentialProfile.defaultId,
  });

  /// The signed-in account of the host app, so two people on one device
  /// never share a business session.
  final String accountId;
  final String businessId;
  final BusinessEnvironment environment;

  /// A [BusinessCredentialProfile.id].
  final String profile;

  /// Whether this is the profile of an environment that declares none.
  bool get isDefaultProfile => profile == BusinessCredentialProfile.defaultId;

  factory BusinessCredentialScope.fromJson(Map<String, Object?> json) =>
      BusinessCredentialScope(
        accountId: json.requiredString('account_id'),
        businessId: json.requiredString('business_id'),
        environment: json.enumValue(BusinessEnvironment.values, 'environment'),
        profile: json.optionalString(
          'profile',
          BusinessCredentialProfile.defaultId,
        ),
      );

  Map<String, Object?> toJson() => {
    'account_id': accountId,
    'business_id': businessId,
    'environment': environment.name,
    'profile': profile,
  };

  BusinessCredentialScope copyWith({
    String? accountId,
    String? businessId,
    BusinessEnvironment? environment,
    String? profile,
  }) => BusinessCredentialScope(
    accountId: accountId ?? this.accountId,
    businessId: businessId ?? this.businessId,
    environment: environment ?? this.environment,
    profile: profile ?? this.profile,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessCredentialScope &&
          accountId == other.accountId &&
          businessId == other.businessId &&
          environment == other.environment &&
          profile == other.profile;

  @override
  int get hashCode => Object.hash(accountId, businessId, environment, profile);
}
