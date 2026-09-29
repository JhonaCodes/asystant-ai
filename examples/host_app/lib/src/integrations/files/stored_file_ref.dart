part of 'files.dart';

/// Where a stored file lives, as written in records:
/// `asset://assets/plants/x.jpg`, `local://photos/x.jpg` or `https://…`.
sealed class StoredFileRef {
  const StoredFileRef();

  factory StoredFileRef.parse(String value) {
    if (value.startsWith(AssetFileRef.scheme)) {
      return AssetFileRef(value.substring(AssetFileRef.scheme.length));
    }
    if (value.startsWith(LocalFileRef.scheme)) {
      final relative = value.substring(LocalFileRef.scheme.length);
      return relative.isEmpty || relative.contains('..')
          ? InvalidFileRef(value)
          : LocalFileRef(relative);
    }
    final uri = Uri.tryParse(value);
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      return RemoteFileRef(uri);
    }
    return InvalidFileRef(value);
  }

  /// The form stored in records.
  String get value;

  @override
  String toString() => value;
}

/// A file bundled with the app.
final class AssetFileRef extends StoredFileRef {
  const AssetFileRef(this.path);

  static const scheme = 'asset://';

  final String path;

  @override
  String get value => '$scheme$path';

  @override
  bool operator ==(Object other) => other is AssetFileRef && path == other.path;

  @override
  int get hashCode => path.hashCode;
}

/// A file the app saved on this device, relative to its vault.
final class LocalFileRef extends StoredFileRef {
  const LocalFileRef(this.relativePath);

  static const scheme = 'local://';

  final String relativePath;

  @override
  String get value => '$scheme$relativePath';

  @override
  bool operator ==(Object other) =>
      other is LocalFileRef && relativePath == other.relativePath;

  @override
  int get hashCode => relativePath.hashCode;
}

/// A file served by a remote API.
final class RemoteFileRef extends StoredFileRef {
  const RemoteFileRef(this.uri);

  final Uri uri;

  @override
  String get value => uri.toString();

  @override
  bool operator ==(Object other) => other is RemoteFileRef && uri == other.uri;

  @override
  int get hashCode => uri.hashCode;
}

/// Anything else; shown as a placeholder.
final class InvalidFileRef extends StoredFileRef {
  const InvalidFileRef(this.value);

  @override
  final String value;

  @override
  bool operator ==(Object other) =>
      other is InvalidFileRef && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
