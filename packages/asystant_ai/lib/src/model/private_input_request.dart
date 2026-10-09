import 'package:asystant_core/asystant_core.dart';

/// Ephemeral metadata for a local tool's private input. Never persisted.
class PrivateInputRequest {
  const PrivateInputRequest({
    required this.id,
    required this.title,
    required this.fields,
  });
  final String id;
  final String title;
  final List<PrivateInputField> fields;

  /// Single source of truth for "required fields complete": every required
  /// field is non-empty, and any value entered matches its kind's shape
  /// (TOTP digits, an email address).
  bool isAnswerComplete(Map<String, String> values) {
    for (final field in fields) {
      final value = values[field.name]?.trim() ?? '';
      if (value.isEmpty) {
        if (field.required) return false;
        continue;
      }
      if (!field.kind.accepts(value)) return false;
    }
    return true;
  }

  static final RegExp _totpPattern = RegExp(r'^\d{6,8}$');
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}

extension on PrivateInputKind {
  bool accepts(String value) => switch (this) {
    .totp => PrivateInputRequest._totpPattern.hasMatch(value),
    .email => PrivateInputRequest._emailPattern.hasMatch(value),
    .secret || .password || .code || .text => true,
  };
}
