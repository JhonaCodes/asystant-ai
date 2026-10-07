import 'package:flutter/material.dart';

import 'package:asystant_core/asystant_core.dart';

/// The five sensitivity levels a host may assign to each tool invocation.
/// The library never infers a level from model-generated text.
enum AsystantSensitivityLevel { none, low, medium, high, admin }

/// Visual identity of a sensitivity level in approvals and activity.
class AsystantSensitivity {
  const AsystantSensitivity({
    required this.name,
    required this.color,
    this.level,
  }) : assert(name != '');

  final String name;
  final Color color;
  final AsystantSensitivityLevel? level;

  static AsystantSensitivity forLevel(AsystantSensitivityLevel level) =>
      switch (level) {
        .none => const AsystantSensitivity(
          name: 'None',
          color: Color(0xFF6B7280),
          level: .none,
        ),
        .low => const AsystantSensitivity(
          name: 'Low',
          color: Color(0xFF2BA68A),
          level: .low,
        ),
        .medium => const AsystantSensitivity(
          name: 'Medium',
          color: Color(0xFFE0A02C),
          level: .medium,
        ),
        .high => const AsystantSensitivity(
          name: 'High',
          color: Color(0xFFE36D45),
          level: .high,
        ),
        .admin => const AsystantSensitivity(
          name: 'Admin',
          color: Color(0xFFAA69D6),
          level: .admin,
        ),
      };

  @override
  bool operator ==(Object other) =>
      other is AsystantSensitivity &&
      name == other.name &&
      color == other.color &&
      level == other.level;

  @override
  int get hashCode => Object.hash(name, color, level);
}

/// Resolved for every invocation, so one tool may classify different actions.
class AsystantActionPolicy {
  const AsystantActionPolicy({
    AsystantSensitivityLevel? level,
    bool? requiresApproval,
    this.sensitivity,
    this.allowSessionApproval = true,
  }) : level =
           level ??
           (requiresApproval == true
               ? AsystantSensitivityLevel.medium
               : AsystantSensitivityLevel.none);

  /// Set by the integrating app, optionally from validated tool arguments.
  final AsystantSensitivityLevel level;

  final AsystantSensitivity? sensitivity;

  /// Whether this invocation needs the person's explicit approval.
  bool get requiresApproval => switch (level) {
    .none || .low => false,
    .medium || .high || .admin => true,
  };

  AsystantSensitivity get displaySensitivity =>
      sensitivity ?? AsystantSensitivity.forLevel(level);

  /// Whether the person may approve this and later eligible actions for the
  /// current signed-in session. Selection input is never skipped.
  final bool allowSessionApproval;

  @override
  bool operator ==(Object other) =>
      other is AsystantActionPolicy &&
      level == other.level &&
      sensitivity == other.sensitivity &&
      allowSessionApproval == other.allowSessionApproval;

  @override
  int get hashCode => Object.hash(level, sensitivity, allowSessionApproval);
}

/// Implement on a tool when sensitivity depends on its validated arguments.
abstract interface class AsystantActionPolicyProvider {
  AsystantActionPolicy actionPolicy(ToolArguments arguments);
}
