part of 'files.dart';

/// Saves and deletes files under `<app support>/botanica_files/`.
class FileVault {
  FileVault();

  static const _folder = 'botanica_files';

  Directory? _root;

  bool get isOpen => _root != null;

  Future<Result<bool, FileVaultFailure>> open() async {
    if (_root != null) {
      return Ok(true);
    }
    try {
      final base = await getApplicationSupportDirectory();
      final root = Directory('${base.path}/$_folder');
      await root.create(recursive: true);
      _root = root;
      return Ok(true);
    } on Exception catch (error, stackTrace) {
      // FileSystemException, or a platform error from path_provider.
      Log.e('File vault did not open', error: error, stackTrace: stackTrace);
      return Err(const FileVaultFailure('The file folder is not available.'));
    }
  }

  /// Writes [bytes] under [folder] with a new name and returns its reference.
  Future<Result<LocalFileRef, FileVaultFailure>> save({
    required Uint8List bytes,
    required String extension,
    String folder = 'photos',
  }) async {
    final root = _root;
    if (root == null) {
      return Err(const FileVaultFailure('The file folder is not open.'));
    }
    final name =
        '${const Uuid().v4()}${extension.isEmpty ? '' : '.$extension'}';
    final relative = '$folder/$name';
    final target = File('${root.path}/$relative');
    final temporary = File('${target.path}.part');
    try {
      await target.parent.create(recursive: true);
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(target.path);
      return Ok(LocalFileRef(relative));
    } on FileSystemException catch (error, stackTrace) {
      Log.e('Saving $relative failed', error: error, stackTrace: stackTrace);
      return Err(const FileVaultFailure('The file could not be saved.'));
    }
  }

  /// Deletes the file behind [ref]; true when it existed.
  Future<Result<bool, FileVaultFailure>> delete(LocalFileRef ref) async {
    final file = fileOf(ref);
    if (file == null || !file.existsSync()) {
      return Ok(false);
    }
    try {
      await file.delete();
      return Ok(true);
    } on FileSystemException catch (error, stackTrace) {
      Log.e('Deleting $ref failed', error: error, stackTrace: stackTrace);
      return Err(const FileVaultFailure('The file could not be deleted.'));
    }
  }

  /// The file behind [ref], once the vault is open.
  File? fileOf(LocalFileRef ref) => switch (_root) {
    final Directory root => File('${root.path}/${ref.relativePath}'),
    null => null,
  };
}
