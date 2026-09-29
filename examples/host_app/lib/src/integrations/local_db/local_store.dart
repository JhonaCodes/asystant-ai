part of 'local_db.dart';

/// Reads from memory, writes to disk first and to memory only on success.
class LocalStore {
  LocalStore();

  final KeyIndex _index = KeyIndex();

  bool _isOpen = false;

  bool get isOpen => _isOpen;

  /// Opens the database and loads every record. Safe to call again.
  Future<Result<bool, LocalStoreFailure>> open() async {
    if (_isOpen) {
      return Ok(true);
    }
    try {
      await db.LocalDB.init();
    } on Exception catch (error, stackTrace) {
      Log.e(
        'Local database did not open',
        error: error,
        stackTrace: stackTrace,
      );
      return Err(
        const LocalStoreFailure(
          kind: LocalStoreFailureKind.unavailable,
          message: 'The local database could not be opened.',
        ),
      );
    }
    final records = await db.LocalDB.GetAll();
    return records.when(
      ok: (models) {
        _index.load(
          models.map(
            (model) => MapEntry(model.id, Map<String, Object?>.of(model.data)),
          ),
        );
        _isOpen = true;
        Log.i('Local database open with ${models.length} records');
        return Ok(true);
      },
      err: (error) {
        Log.e('Local database could not be read: ${error.message}');
        return Err(
          LocalStoreFailure(
            kind: LocalStoreFailureKind.unavailable,
            message: error.message,
          ),
        );
      },
    );
  }

  Map<String, Object?>? read(String key) => _index[key];

  List<Map<String, Object?>> readPrefix(String prefix) => [
    for (final entry in _index.withPrefix(prefix)) entry.value,
  ];

  /// Creates or replaces the record at [key].
  Future<Result<Map<String, Object?>, LocalStoreFailure>> write(
    String key,
    Map<String, Object?> data,
  ) async {
    if (!_isOpen) {
      return Err(_notOpen);
    }
    final written = await db.LocalDB.Put(key, data);
    return written.when(
      ok: (_) {
        _index.put(key, data);
        return Ok(data);
      },
      err: (error) {
        Log.e('Local write of $key failed: ${error.message}');
        return Err(
          LocalStoreFailure(
            kind: LocalStoreFailureKind.write,
            message: error.message,
          ),
        );
      },
    );
  }

  /// Deletes the record at [key]; true when it existed.
  Future<Result<bool, LocalStoreFailure>> remove(String key) async {
    if (!_isOpen) {
      return Err(_notOpen);
    }
    if (_index[key] == null) {
      return Ok(false);
    }
    final removed = await db.LocalDB.Delete(key);
    return removed.when(
      ok: (_) {
        _index.remove(key);
        return Ok(true);
      },
      err: (error) {
        Log.e('Local delete of $key failed: ${error.message}');
        return Err(
          LocalStoreFailure(
            kind: LocalStoreFailureKind.write,
            message: error.message,
          ),
        );
      },
    );
  }

  static const _notOpen = LocalStoreFailure(
    kind: LocalStoreFailureKind.notOpen,
    message: 'The local database is not open yet.',
  );
}
