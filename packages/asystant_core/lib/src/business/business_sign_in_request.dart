import 'package:collection/collection.dart';

import 'package:asystant_core/src/business/business_auth_input.dart';
import 'package:asystant_core/src/business/business_auth_step_kind.dart';
import 'package:asystant_core/src/business/business_totp_enrollment.dart';

/// Asks the person for what the next sign-in step needs, through a secure
/// form the host shows. Answers the values keyed by
/// [BusinessAuthInput.name] (and the parameters by
/// [BusinessSignInRequest.parameterKey]), or null when the person dismisses
/// it.
typedef BusinessSignInPrompter = Future<Map<String, String>?> Function(
  BusinessSignInRequest request,
);

/// What one sign-in form asks for, before the step [step] runs.
///
/// Transient: it lives for one form and is never serialized, so it has no
/// JSON form.
class BusinessSignInRequest {
  const BusinessSignInRequest({
    required this.step,
    this.inputs = const [],
    this.parameters = const {},
    this.requiredParameters = const [],
    this.initialValues = const {},
    this.previousStep,
    this.enrollment,
  });

  /// The step that runs with the answer.
  final BusinessAuthStepKind step;

  /// What the person types now; an input asked before is not repeated.
  final List<BusinessAuthInput> inputs;

  /// The flow's fixed parameters with their current values, for the person
  /// to confirm or correct. Only the first form carries them.
  final Map<String, String> parameters;

  /// The [parameters] that cannot be left empty.
  final List<String> requiredParameters;

  /// Values to pre-fill by input name, such as the last email used. Never
  /// a password or code.
  final Map<String, String> initialValues;

  /// The step that ran just before, such as [BusinessAuthStepKind.request]
  /// when the API has just sent a code; null for the first form.
  final BusinessAuthStepKind? previousStep;

  /// A new authenticator to add before typing its code, when the API sent
  /// one.
  final BusinessTotpEnrollment? enrollment;

  /// The answer key of the sign-in parameter [name].
  static String parameterKey(String name) => 'parameter.$name';

  BusinessSignInRequest copyWith({
    BusinessAuthStepKind? step,
    List<BusinessAuthInput>? inputs,
    Map<String, String>? parameters,
    List<String>? requiredParameters,
    Map<String, String>? initialValues,
    BusinessAuthStepKind? previousStep,
    BusinessTotpEnrollment? enrollment,
  }) => BusinessSignInRequest(
    step: step ?? this.step,
    inputs: inputs ?? this.inputs,
    parameters: parameters ?? this.parameters,
    requiredParameters: requiredParameters ?? this.requiredParameters,
    initialValues: initialValues ?? this.initialValues,
    previousStep: previousStep ?? this.previousStep,
    enrollment: enrollment ?? this.enrollment,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessSignInRequest &&
          step == other.step &&
          const ListEquality<BusinessAuthInput>().equals(
            inputs,
            other.inputs,
          ) &&
          const MapEquality<String, String>().equals(
            parameters,
            other.parameters,
          ) &&
          const ListEquality<String>().equals(
            requiredParameters,
            other.requiredParameters,
          ) &&
          const MapEquality<String, String>().equals(
            initialValues,
            other.initialValues,
          ) &&
          previousStep == other.previousStep &&
          enrollment == other.enrollment;

  @override
  int get hashCode => Object.hash(
    step,
    Object.hashAll(inputs),
    const MapEquality<String, String>().hash(parameters),
    Object.hashAll(requiredParameters),
    const MapEquality<String, String>().hash(initialValues),
    previousStep,
    enrollment,
  );
}
