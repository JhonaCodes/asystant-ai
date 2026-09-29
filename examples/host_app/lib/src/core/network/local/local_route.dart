/// A request path understood by [LocalApi]: `/{collection}`,
/// `/{collection}/{id}`, `/files` or `/files/{id}`.
sealed class LocalRoute {
  const LocalRoute();

  static final _segment = RegExp(r'^[a-z0-9_-]{1,64}$');

  static const _files = 'files';

  factory LocalRoute.parse(String path) {
    final segments = path.split('/').where((part) => part.isNotEmpty).toList();
    if (segments.isEmpty ||
        segments.length > 2 ||
        !segments.every(_segment.hasMatch)) {
      return const InvalidRoute();
    }
    return switch (segments) {
      [_files] => const FilesRoute(),
      [_files, final id] => FileRoute(id),
      [final collection] => CollectionRoute(collection),
      [final collection, final id] => ItemRoute(collection, id),
      _ => const InvalidRoute(),
    };
  }
}

final class CollectionRoute extends LocalRoute {
  const CollectionRoute(this.collection);

  final String collection;

  /// Every record of the collection is stored under this key prefix.
  String get prefix => '$collection:';
}

final class ItemRoute extends LocalRoute {
  const ItemRoute(this.collection, this.id);

  final String collection;

  final String id;

  String get key => '$collection:$id';
}

final class FilesRoute extends LocalRoute {
  const FilesRoute();
}

final class FileRoute extends LocalRoute {
  const FileRoute(this.id);

  final String id;

  String get key => 'files:$id';
}

final class InvalidRoute extends LocalRoute {
  const InvalidRoute();
}
