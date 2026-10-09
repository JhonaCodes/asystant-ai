import 'package:asystant_core/asystant_core.dart';

/// Which registered business a call targets, and optionally its
/// environment (`DEV` or `PROD`), credential profile and email. Decoded
/// tool input: transient, never serialized, so it has no JSON form.
class BusinessCallTarget {
  const BusinessCallTarget({
    required this.business,
    this.environment,
    this.profile,
    this.email = '',
  });

  final BusinessContract business;
  final String? environment;
  final String? profile;
  final String email;

  BusinessCallTarget copyWith({
    BusinessContract? business,
    String? environment,
    String? profile,
    String? email,
  }) => BusinessCallTarget(
    business: business ?? this.business,
    environment: environment ?? this.environment,
    profile: profile ?? this.profile,
    email: email ?? this.email,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessCallTarget &&
          business == other.business &&
          environment == other.environment &&
          profile == other.profile &&
          email == other.email;

  @override
  int get hashCode => Object.hash(business, environment, profile, email);
}
