import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/model/asystant_action_policy.dart';

/// Which business operations wait for the person's approval. By default
/// only what cannot be undone, a `DELETE`, at [AsystantSensitivityLevel.high]
/// and approved every time; every other business tool runs directly.
///
/// Configuration held by a `BusinessToolkit`, never serialized, so it has
/// no JSON form.
class BusinessApprovalPolicy {
  const BusinessApprovalPolicy({
    this.destructiveMethods = const {'DELETE'},
    this.level = AsystantSensitivityLevel.high,
    this.allowsSessionApproval = false,
  });

  /// HTTP methods that need approval, upper case.
  final Set<String> destructiveMethods;

  /// The sensitivity shown when approval is needed.
  final AsystantSensitivityLevel level;

  /// Whether one approval may cover later destructive calls of the session.
  final bool allowsSessionApproval;

  /// The policy of one call to [operation].
  AsystantActionPolicy forOperation(BusinessOperation operation) =>
      destructiveMethods.contains(operation.method)
      ? AsystantActionPolicy(
          level: level,
          allowSessionApproval: allowsSessionApproval,
        )
      : const AsystantActionPolicy();

  BusinessApprovalPolicy copyWith({
    Set<String>? destructiveMethods,
    AsystantSensitivityLevel? level,
    bool? allowsSessionApproval,
  }) => BusinessApprovalPolicy(
    destructiveMethods: destructiveMethods ?? this.destructiveMethods,
    level: level ?? this.level,
    allowsSessionApproval: allowsSessionApproval ?? this.allowsSessionApproval,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessApprovalPolicy &&
          destructiveMethods.length == other.destructiveMethods.length &&
          destructiveMethods.containsAll(other.destructiveMethods) &&
          level == other.level &&
          allowsSessionApproval == other.allowsSessionApproval;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(destructiveMethods),
    level,
    allowsSessionApproval,
  );
}
