import 'package:collection/collection.dart';

import 'package:asystant_core/asystant_core.dart';

/// One decoded call of `OperateBusinessTool`: the operation, the optional
/// environment (`DEV` or `PROD`) and profile, and the validated JSON
/// [arguments] without secret fields. Transient tool input, never
/// serialized, so it has no JSON form.
class BusinessOperationCall {
  const BusinessOperationCall({
    required this.business,
    required this.operation,
    this.environment,
    this.profile,
    this.arguments = const {},
  });

  final BusinessContract business;
  final BusinessOperation operation;
  final String? environment;
  final String? profile;

  /// The JSON parameters the API receives, already checked against the
  /// operation's typed fields.
  final Map<String, Object?> arguments;

  BusinessOperationCall copyWith({
    BusinessContract? business,
    BusinessOperation? operation,
    String? environment,
    String? profile,
    Map<String, Object?>? arguments,
  }) => BusinessOperationCall(
    business: business ?? this.business,
    operation: operation ?? this.operation,
    environment: environment ?? this.environment,
    profile: profile ?? this.profile,
    arguments: arguments ?? this.arguments,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessOperationCall &&
          business == other.business &&
          operation == other.operation &&
          environment == other.environment &&
          profile == other.profile &&
          const DeepCollectionEquality().equals(arguments, other.arguments);

  @override
  int get hashCode => Object.hash(
    business,
    operation,
    environment,
    profile,
    const DeepCollectionEquality().hash(arguments),
  );
}
