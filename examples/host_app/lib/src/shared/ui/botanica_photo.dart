part of 'ui.dart';

/// Shows a stored photo from the app bundle, this device or a server.
class BotanicaPhoto extends StatelessWidget {
  const BotanicaPhoto({
    super.key,
    required this.ref,
    this.size,
    this.fit = BoxFit.cover,
    this.radius = AppRadius.md,
  });

  /// A [StoredFileRef] value: `asset://`, `local://` or `https://`.
  final String ref;

  /// Square side; fills the parent when null.
  final double? size;

  final BoxFit fit;

  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: SizedBox(
      width: size,
      height: size,
      child: switch (StoredFileRef.parse(ref)) {
        AssetFileRef(:final path) => Image.asset(
          path,
          fit: fit,
          errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
        ),
        final LocalFileRef local => switch (FilesService.vault.notifier.fileOf(
          local,
        )) {
          final file? => Image.file(
            file,
            fit: fit,
            errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
          ),
          null => const _PhotoPlaceholder(),
        },
        RemoteFileRef(:final uri) => Image.network(
          uri.toString(),
          fit: fit,
          errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
        ),
        InvalidFileRef() => const _PhotoPlaceholder(),
      },
    ),
  );
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Icon(
      Icons.local_florist_outlined,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}
