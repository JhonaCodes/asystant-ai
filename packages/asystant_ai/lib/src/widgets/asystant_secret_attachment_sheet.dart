import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';

enum _SecretKind { apiKey, token, url, password, other }

/// The sheet returns the raw value to its caller only. The caller immediately
/// reserves it in the in-memory vault and inserts only the reference in chat.
Future<({String label, String value})?> showAsystantSecretAttachmentSheet(
  BuildContext context, {
  required AsystantStrings strings,
}) => showModalBottomSheet<({String label, String value})>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => _SecretAttachmentSheet(strings: strings),
);

class _SecretAttachmentSheet extends StatefulWidget {
  const _SecretAttachmentSheet({required this.strings});

  final AsystantStrings strings;

  @override
  State<_SecretAttachmentSheet> createState() => _SecretAttachmentSheetState();
}

class _SecretAttachmentSheetState extends State<_SecretAttachmentSheet> {
  final _value = TextEditingController();
  final _customName = TextEditingController();
  _SecretKind _kind = .apiKey;
  bool _visible = false;

  @override
  void dispose() {
    _value.clear();
    _value.dispose();
    _customName.dispose();
    super.dispose();
  }

  String _label(_SecretKind kind) => switch (kind) {
    .apiKey => widget.strings.privateApiKey,
    .token => widget.strings.privateToken,
    .url => widget.strings.privateUrl,
    .password => widget.strings.privatePassword,
    .other => widget.strings.privateOther,
  };

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final colors = Theme.of(context).colorScheme;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = keyboard > 0
        ? 0.0
        : MediaQueryData.fromView(View.of(context)).viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, keyboard + safeBottom + 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: .stretch,
            children: [
              Text(
                strings.privateValueTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                strings.privateValueDescription,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<_SecretKind>(
                initialValue: _kind,
                decoration: InputDecoration(
                  labelText: strings.privateValueType,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final kind in _SecretKind.values)
                    DropdownMenuItem(value: kind, child: Text(_label(kind))),
                ],
                onChanged: (kind) {
                  if (kind != null) setState(() => _kind = kind);
                },
              ),
              if (_kind == .other) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _customName,
                  maxLength: 80,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: strings.privateCustomName,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _value,
                autofocus: true,
                obscureText: !_visible,
                enableSuggestions: false,
                autocorrect: false,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                maxLines: 1,
                maxLength: 8192,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: strings.privateValueField,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _visible
                        ? strings.hidePrivateValue
                        : strings.showPrivateValue,
                    onPressed: () => setState(() => _visible = !_visible),
                    icon: Icon(
                      _visible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.privateValueHint,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(strings.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          _value.text.trim().isEmpty ||
                              (_kind == .other &&
                                  _customName.text.trim().isEmpty)
                          ? null
                          : () => Navigator.pop(context, (
                              label: _kind == .other
                                  ? _customName.text.trim()
                                  : _label(_kind),
                              value: _value.text,
                            )),
                      icon: const Icon(Icons.lock_outline),
                      label: Text(strings.attachPrivateValue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
