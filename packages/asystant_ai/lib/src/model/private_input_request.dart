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
  /// field is non-empty and any TOTP value matches the expected digits.
  bool isAnswerComplete(Map<String, String> values) {
    for (final field in fields) {
      final value = values[field.name]?.trim() ?? '';
      if (field.required && value.isEmpty) return false;
      if (field.kind == PrivateInputKind.totp &&
          value.isNotEmpty &&
          !_totpPattern.hasMatch(value)) {
        return false;
      }
    }
    return true;
  }

  static final RegExp _totpPattern = RegExp(r'^\d{6,8}$');
}
