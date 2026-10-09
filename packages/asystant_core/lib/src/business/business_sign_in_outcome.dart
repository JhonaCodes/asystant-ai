import 'package:collection/collection.dart';

/// How a sign-in ended: the email it used and the sign-in parameters the
/// person confirmed, so the host can keep them when they changed.
///
/// Transient: the session itself is already in the credential store, so it
/// has no JSON form.
class BusinessSignInOutcome {
  const BusinessSignInOutcome({
    this.email = '',
    this.parameters = const {},
    this.hasChangedParameters = false,
  });

  /// The email typed for the sign-in; empty when the flow asks none.
  final String email;

  /// The flow's parameters as sent, after the person's corrections.
  final Map<String, String> parameters;

  /// Whether [parameters] differ from the contract's.
  final bool hasChangedParameters;

  BusinessSignInOutcome copyWith({
    String? email,
    Map<String, String>? parameters,
    bool? hasChangedParameters,
  }) => BusinessSignInOutcome(
    email: email ?? this.email,
    parameters: parameters ?? this.parameters,
    hasChangedParameters: hasChangedParameters ?? this.hasChangedParameters,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessSignInOutcome &&
          email == other.email &&
          const MapEquality<String, String>().equals(
            parameters,
            other.parameters,
          ) &&
          hasChangedParameters == other.hasChangedParameters;

  @override
  int get hashCode => Object.hash(
    email,
    const MapEquality<String, String>().hash(parameters),
    hasChangedParameters,
  );
}
