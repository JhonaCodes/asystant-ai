part of 'ui.dart';

/// A load that failed, with a way to try again.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: BotanicaColors.of(context).danger,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(CommonStrings.loadFailed, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text(CommonStrings.retry),
          ),
        ],
      ),
    ),
  );
}
