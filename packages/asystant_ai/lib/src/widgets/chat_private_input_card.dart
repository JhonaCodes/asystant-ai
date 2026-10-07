import 'package:asystant_core/asystant_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:asystant_ai/src/model/private_input_request.dart';
import 'package:asystant_ai/src/l10n/asystant_strings.dart';

/// Inline, ephemeral input for a local tool. Controllers never enter chat state.
class ChatPrivateInputCard extends StatefulWidget {
  const ChatPrivateInputCard({
    super.key,
    required this.request,
    required this.strings,
    required this.onSubmit,
    required this.onCancel,
  });
  final PrivateInputRequest request;
  final AsystantStrings strings;
  final ValueChanged<Map<String, String>> onSubmit;
  final VoidCallback onCancel;

  @override
  State<ChatPrivateInputCard> createState() => _ChatPrivateInputCardState();
}

class _ChatPrivateInputCardState extends State<ChatPrivateInputCard> {
  late final Map<String, TextEditingController> _controllers = {
    for (final field in widget.request.fields)
      field.name: TextEditingController(),
  };
  bool _show = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.clear();
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final values = {
      for (final entry in _controllers.entries)
        entry.key: entry.value.text.trim(),
    };
    for (final field in widget.request.fields) {
      if (field.required && (values[field.name]?.isEmpty ?? true)) return;
      if (field.kind == PrivateInputKind.totp &&
          values[field.name]!.isNotEmpty &&
          !RegExp(r'^\d{6,8}$').hasMatch(values[field.name]!))
        return;
    }
    widget.onSubmit(values);
    for (final controller in _controllers.values) {
      controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.request.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.strings.privateInputHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final field in widget.request.fields)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: _controllers[field.name],
                  obscureText: !_show && field.kind != PrivateInputKind.text,
                  enableSuggestions: false,
                  autocorrect: false,
                  keyboardType:
                      field.kind == PrivateInputKind.totp ||
                          field.kind == PrivateInputKind.code
                      ? TextInputType.number
                      : TextInputType.text,
                  inputFormatters: field.kind == PrivateInputKind.totp
                      ? [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                        ]
                      : null,
                  decoration: InputDecoration(
                    labelText: field.label,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _show = !_show),
                  icon: Icon(_show ? Icons.visibility_off : Icons.visibility),
                  tooltip: _show
                      ? widget.strings.hidePrivateInput
                      : widget.strings.showPrivateInput,
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.onCancel,
                  child: Text(widget.strings.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed:
                      widget.request.fields.every(
                        (field) =>
                            !field.required ||
                            _controllers[field.name]!.text.trim().isNotEmpty,
                      )
                      ? _submit
                      : null,
                  child: Text(widget.strings.continueAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
