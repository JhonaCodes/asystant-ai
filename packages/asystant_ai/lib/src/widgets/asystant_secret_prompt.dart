import 'package:flutter/material.dart';

/// Collects one-time values on the device after the action is approved.
/// Values are returned to the caller only and are never added to chat state.
Future<Map<String, String>?> showAsystantSecretPrompt(
  BuildContext context, {
  required String title,
  required List<String> fieldNames,
  String cancelLabel = 'Cancel',
  String continueLabel = 'Continue',
  String requiredMessage = 'Complete every field.',
}) => showDialog<Map<String, String>>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _SecretPrompt(
    title: title,
    fieldNames: fieldNames,
    cancelLabel: cancelLabel,
    continueLabel: continueLabel,
    requiredMessage: requiredMessage,
  ),
);

class _SecretPrompt extends StatefulWidget {
  const _SecretPrompt({
    required this.title,
    required this.fieldNames,
    required this.cancelLabel,
    required this.continueLabel,
    required this.requiredMessage,
  });

  final String title;
  final List<String> fieldNames;
  final String cancelLabel;
  final String continueLabel;
  final String requiredMessage;

  @override
  State<_SecretPrompt> createState() => _SecretPromptState();
}

class _SecretPromptState extends State<_SecretPrompt> {
  late final controllers = {
    for (final name in widget.fieldNames) name: TextEditingController(),
  };
  bool invalid = false;

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in controllers.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: entry.value,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(labelText: entry.key),
              ),
            ),
          if (invalid)
            Text(
              widget.requiredMessage,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(widget.cancelLabel),
      ),
      FilledButton(
        onPressed: () {
          if (controllers.values.any((controller) => controller.text.isEmpty)) {
            setState(() => invalid = true);
            return;
          }
          Navigator.pop(context, {
            for (final entry in controllers.entries)
              entry.key: entry.value.text,
          });
        },
        child: Text(widget.continueLabel),
      ),
    ],
  );
}
