import 'package:asystant_core/src/business/business_json_reading.dart';

/// One identity an environment can be operated with, such as `admin` and
/// `guest`: each profile signs in separately and keeps its own session.
class BusinessCredentialProfile {
  const BusinessCredentialProfile({required this.id, this.label = ''});

  /// The profile an environment uses when it declares none.
  static const String defaultId = 'default';

  /// The single profile of an environment that declares none.
  static const BusinessCredentialProfile fallback = BusinessCredentialProfile(
    id: defaultId,
  );

  /// Lower-case identifier, such as `admin`.
  final String id;

  /// What the person reads; empty shows [id].
  final String label;

  /// Whether this is the profile of an environment that declares none.
  bool get isDefault => id == defaultId;

  factory BusinessCredentialProfile.fromJson(Map<String, Object?> json) =>
      BusinessCredentialProfile(
        id: json.requiredString('id'),
        label: json.optionalString('label', ''),
      );

  Map<String, Object?> toJson() => {
    'id': id,
    if (label.isNotEmpty) 'label': label,
  };

  BusinessCredentialProfile copyWith({String? id, String? label}) =>
      BusinessCredentialProfile(id: id ?? this.id, label: label ?? this.label);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessCredentialProfile &&
          id == other.id &&
          label == other.label;

  @override
  int get hashCode => Object.hash(id, label);
}
