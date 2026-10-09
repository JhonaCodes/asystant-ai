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
      field.name: TextEditingController(text: field.toInitialText()),
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

  Map<String, String> get _values => {
    for (final entry in _controllers.entries)
      entry.key: entry.value.text.trim(),
  };

  void _submit() {
    final values = _values;
    if (!widget.request.isAnswerComplete(values)) return;
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
            ...widget.request.fields.map(
              (field) => _PrivateInputTextField(
                field: field,
                controller: _controllers[field.name],
                isRevealed: _show,
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
                  onPressed: widget.request.isAnswerComplete(_values)
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

class _PrivateInputTextField extends StatelessWidget {
  const _PrivateInputTextField({
    required this.field,
    required this.controller,
    required this.isRevealed,
    required this.onChanged,
  });

  final PrivateInputField field;
  final TextEditingController? controller;
  final bool isRevealed;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      obscureText: !isRevealed && field.kind.isObscured,
      enableSuggestions: false,
      autocorrect: false,
      keyboardType: field.kind.toKeyboardType(),
      autofillHints: field.kind.toAutofillHints(),
      inputFormatters: field.kind.toInputFormatters(),
      decoration: InputDecoration(
        labelText: field.label,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    ),
  );
}

extension on PrivateInputField {
  /// [PrivateInputField.initialValue] for a public field; always empty for a
  /// secret one, whatever the tool sent.
  String toInitialText() => switch (kind) {
    .text || .email => initialValue ?? '',
    .secret || .password || .code || .totp => '',
  };
}

extension on PrivateInputKind {
  bool get isObscured => switch (this) {
    .text || .email => false,
    .secret || .password || .code || .totp => true,
  };

  TextInputType toKeyboardType() => switch (this) {
    .totp || .code => .number,
    .email => .emailAddress,
    .secret || .password || .text => .text,
  };

  Iterable<String> toAutofillHints() => switch (this) {
    .email => const [AutofillHints.email],
    .secret || .password || .code || .totp || .text => const [],
  };

  List<TextInputFormatter>? toInputFormatters() => switch (this) {
    .totp => [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(8),
    ],
    .secret || .password || .code || .text || .email => null,
  };
}
