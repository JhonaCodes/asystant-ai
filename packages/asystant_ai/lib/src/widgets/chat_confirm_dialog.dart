import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';

/// Asks before something that cannot be undone. Resolves to true on confirm.
Future<bool> showChatConfirmDialog(
  BuildContext context, {
  required AsystantStrings strings,
  required String title,
  required String body,
  required String confirmLabel,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => _ChatConfirmDialog(
        strings: strings,
        title: title,
        body: body,
        confirmLabel: confirmLabel,
      ),
    ) ??
    false;

class _ChatConfirmDialog extends StatelessWidget {
  const _ChatConfirmDialog({
    required this.strings,
    required this.title,
    required this.body,
    required this.confirmLabel,
  });

  final AsystantStrings strings;

  final String title;

  final String body;

  final String confirmLabel;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: Text(body),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: Text(strings.cancel),
      ),
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        onPressed: () => Navigator.of(context).pop(true),
        child: Text(confirmLabel),
      ),
    ],
  );
}
