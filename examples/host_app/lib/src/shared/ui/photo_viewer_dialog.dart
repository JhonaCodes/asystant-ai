part of 'ui.dart';

/// A photo at full size, with its credit line when it has one.
class PhotoViewerDialog extends StatelessWidget {
  const PhotoViewerDialog({super.key, required this.ref, this.credit = ''});

  final String ref;

  final String credit;

  static Future<void> show(
    BuildContext context, {
    required String ref,
    String credit = '',
  }) => showDialog<void>(
    context: context,
    builder: (_) => PhotoViewerDialog(ref: ref, credit: credit),
  );

  @override
  Widget build(BuildContext context) => Dialog(
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InteractiveViewer(
          child: BotanicaPhoto(ref: ref, fit: BoxFit.contain, radius: 0),
        ),
        if (credit.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(credit, style: Theme.of(context).textTheme.bodySmall),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(CommonStrings.close),
        ),
      ],
    ),
  );
}
