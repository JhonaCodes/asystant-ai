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
}
