import 'package:asystant_core/src/business/business_auth_input_kind.dart';
import 'package:asystant_core/src/business/business_json_reading.dart';

/// A value the person types to sign in, and the body member the API reads
/// it from.
///
/// Inputs are identified by [name] across the whole flow: when two steps
/// send the same input (the email of a code request and of its
/// verification), the person types it once.
class BusinessAuthInput {
  const BusinessAuthInput({
    required this.name,
    required this.kind,
    required this.field,
    this.label = '',
  });

  /// The email the person signs in with, sent as [field].
  const BusinessAuthInput.email({String field = 'email'})
    : this(name: 'email', kind: .email, field: field);

  /// The password, sent as [field].
  const BusinessAuthInput.password({String field = 'password'})
    : this(name: 'password', kind: .password, field: field);

  /// The one-time code the API sent, sent as [field].
  const BusinessAuthInput.code({String field = 'code'})
    : this(name: 'code', kind: .code, field: field);

  /// The authenticator code of a second factor, sent as [field].
  const BusinessAuthInput.totp({String field = 'code'})
    : this(name: 'totp', kind: .totp, field: field);

  /// Identifies the value within the flow, such as `email` or `totp`.
  final String name;

  /// How the form shows it.
  final BusinessAuthInputKind kind;

  /// The JSON body member the API expects, such as `email` or `code`.
  final String field;

  /// The label the form shows; empty uses the host's label for [kind].
  final String label;

  factory BusinessAuthInput.fromJson(Map<String, Object?> json) {
    final name = json.requiredString('name');
    return BusinessAuthInput(
      name: name,
      kind: json.enumValue(BusinessAuthInputKind.values, 'kind'),
      field: json.optionalString('field', name),
      label: json.optionalString('label', ''),
    );
  }

  Map<String, Object?> toJson() => {
    'name': name,
    'kind': kind.name,
    'field': field,
    if (label.isNotEmpty) 'label': label,
  };

  BusinessAuthInput copyWith({
    String? name,
    BusinessAuthInputKind? kind,
    String? field,
    String? label,
  }) => BusinessAuthInput(
    name: name ?? this.name,
    kind: kind ?? this.kind,
    field: field ?? this.field,
    label: label ?? this.label,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessAuthInput &&
          name == other.name &&
          kind == other.kind &&
          field == other.field &&
          label == other.label;

  @override
  int get hashCode => Object.hash(name, kind, field, label);
}
