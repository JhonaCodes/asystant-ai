part of 'ui.dart';

/// Asks before something that cannot be undone; resolves to true on confirm.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.body,
    this.confirmLabel = CommonStrings.delete,
  });

  final String title;

  final String body;

  final String confirmLabel;

  static Future<bool> ask(
    BuildContext context, {
    required String title,
    required String body,
    String confirmLabel = CommonStrings.delete,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) =>
            ConfirmDialog(title: title, body: body, confirmLabel: confirmLabel),
      ) ??
      false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: Text(body),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text(CommonStrings.cancel),
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
