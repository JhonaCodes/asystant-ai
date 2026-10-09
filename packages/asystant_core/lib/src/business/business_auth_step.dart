import 'package:collection/collection.dart';

import 'package:asystant_core/src/business/business_auth_input.dart';
import 'package:asystant_core/src/business/business_auth_step_kind.dart';
import 'package:asystant_core/src/business/business_json_reading.dart';

/// One `POST` of a [BusinessAuthFlow]: where it goes and what its JSON body
/// carries.
///
/// The body is built from the flow's parameters (when [sendsParameters]),
/// the [inputs] the person typed and, through [carry], values the previous
/// step's answer returned, such as a second-factor challenge.
class BusinessAuthStep {
  const BusinessAuthStep({
    required this.kind,
    required this.path,
    this.inputs = const [],
    this.carry = const {},
    this.sendsParameters = true,
    this.completesWithToken = false,
    this.continueFlag = '',
  });

  final BusinessAuthStepKind kind;

  /// Starts with `/`, relative to the flow's address.
  final String path;

  /// What the person types for this step. An input another step already
  /// asked for is reused, not asked again.
  final List<BusinessAuthInput> inputs;

  /// Body member → dotted path in the previous step's answer, such as
  /// `{'totp_token': 'totp_token'}` for a password step that answers with a
  /// second-factor challenge. A 4xx answer that carries every one of these
  /// values continues the sign-in instead of failing it.
  final Map<String, String> carry;

  /// Whether the flow's fixed parameters (`company_id`, `application_id`)
  /// go in this step's body.
  final bool sendsParameters;

  /// Whether this step, when it is not the last one, finishes the sign-in
  /// as soon as its answer has the token: a password step whose account
  /// has no second factor.
  final bool completesWithToken;

  /// Dotted path of an answer flag that, when `true`, means the sign-in
  /// continues to the next step even if a token came back, such as
  /// `requires_2fa`. Empty when there is none.
  final String continueFlag;

  factory BusinessAuthStep.fromJson(Map<String, Object?> json) {
    final kind = json.enumValue(BusinessAuthStepKind.values, 'kind');
    return BusinessAuthStep(
      kind: kind,
      path: json.requiredString('path'),
      inputs: [
        for (final input in json.objectList('inputs'))
          BusinessAuthInput.fromJson(input),
      ],
      carry: json.stringMap('carry'),
      sendsParameters: json.optionalBool(
        'sends_parameters',
        fallback: kind != BusinessAuthStepKind.refresh,
      ),
      completesWithToken: json.optionalBool(
        'completes_with_token',
        fallback: false,
      ),
      continueFlag: json.optionalString('continue_flag', ''),
    );
  }

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'path': path,
    if (inputs.isNotEmpty)
      'inputs': inputs.map((input) => input.toJson()).toList(),
    if (carry.isNotEmpty) 'carry': carry,
    'sends_parameters': sendsParameters,
    if (completesWithToken) 'completes_with_token': true,
    if (continueFlag.isNotEmpty) 'continue_flag': continueFlag,
  };

  BusinessAuthStep copyWith({
    BusinessAuthStepKind? kind,
    String? path,
    List<BusinessAuthInput>? inputs,
    Map<String, String>? carry,
    bool? sendsParameters,
    bool? completesWithToken,
    String? continueFlag,
  }) => BusinessAuthStep(
    kind: kind ?? this.kind,
    path: path ?? this.path,
    inputs: inputs ?? this.inputs,
    carry: carry ?? this.carry,
    sendsParameters: sendsParameters ?? this.sendsParameters,
    completesWithToken: completesWithToken ?? this.completesWithToken,
    continueFlag: continueFlag ?? this.continueFlag,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessAuthStep &&
          kind == other.kind &&
          path == other.path &&
          const ListEquality<BusinessAuthInput>().equals(
            inputs,
            other.inputs,
          ) &&
          const MapEquality<String, String>().equals(carry, other.carry) &&
          sendsParameters == other.sendsParameters &&
          completesWithToken == other.completesWithToken &&
          continueFlag == other.continueFlag;

  @override
  int get hashCode => Object.hash(
    kind,
    path,
    Object.hashAll(inputs),
    const MapEquality<String, String>().hash(carry),
    sendsParameters,
    completesWithToken,
    continueFlag,
  );
}
