import 'package:logger_rs/logger_rs.dart';
import 'package:result_controller/result_controller.dart';

import 'package:host_app/src/core/network/api_failure.dart';
import 'package:uuid/uuid.dart';

import 'package:host_app/src/core/network/api_impl.dart';
import 'package:host_app/src/core/network/file_upload.dart';
import 'package:host_app/src/core/network/local/local_route.dart';
import 'package:host_app/src/core/network/local/local_seed.dart';
import 'package:host_app/src/integrations/files/files.dart';
import 'package:host_app/src/integrations/local_db/local_db.dart';

/// [ApiImpl] answered from the device.
///
/// It knows no business: any `/{collection}` is a list of JSON documents
/// stored under `{collection}:{id}`, and `/files` keeps binary files in the
/// file vault. Status codes and error titles follow HTTP so a remote
/// backend can take its place unchanged.
class LocalApi implements ApiImpl {
  LocalApi();

  LocalStore get _store => LocalDbService.store.notifier;

  FileVault get _vault => FilesService.vault.notifier;

  @override
  Future<Result<bool, ApiFailure>> open() async {
    final store = await _store.open();
    if (store.errorOrNull case final LocalStoreFailure failure) {
      return Err(_storage(failure.message));
    }
    final vault = await _vault.open();
    if (vault.errorOrNull case final FileVaultFailure failure) {
      return Err(_storage(failure.message));
    }
    final seed = await LocalSeed.apply(_store);
    return seed.when(
      ok: (_) => Ok(true),
      err: (failure) => Err(_storage(failure.message)),
    );
  }

  @override
  Future<ApiResult<Map<String, Object?>>> get(Params<Object?> params) async =>
      await _unavailable() ?? await _get(params);

  @override
  Future<ApiResult<Map<String, Object?>>> post(Params<Object?> params) async =>
      await _unavailable() ?? await _post(params);

  @override
  Future<ApiResult<Map<String, Object?>>> put(Params<Object?> params) async =>
      await _unavailable() ?? await _put(params);

  @override
  Future<ApiResult<Map<String, Object?>>> patch(Params<Object?> params) async =>
      await _unavailable() ?? await _patch(params);

  @override
  Future<ApiResult<Map<String, Object?>>> delete(
    Params<Object?> params,
  ) async => await _unavailable() ?? await _delete(params);

  /// Reopens storage that is not open; an error response when it cannot.
  Future<ApiResult<Map<String, Object?>>?> _unavailable() async {
    if (_store.isOpen && _vault.isOpen) {
      return null;
    }
    final opened = await open();
    return switch (opened.errorOrNull) {
      final ApiFailure failure => _fail(failure, 503),
      null => null,
    };
  }

  Future<ApiResult<Map<String, Object?>>> _get(Params<Object?> params) async =>
      switch (LocalRoute.parse(params.path)) {
        CollectionRoute(:final prefix) => _ok({
          'data': _store.readPrefix(prefix),
        }),
        ItemRoute(:final key) => switch (_store.read(key)) {
          final Map<String, Object?> document => _ok({'data': document}),
          null => _notFound(params.path),
        },
        FileRoute(:final key) => switch (_store.read(key)) {
          final Map<String, Object?> file => _ok({'data': file}),
          null => _notFound(params.path),
        },
        FilesRoute() => _notAllowed(params.path),
        InvalidRoute() => _badRequest(params.path),
      };

  Future<ApiResult<Map<String, Object?>>> _post(Params<Object?> params) async =>
      switch (LocalRoute.parse(params.path)) {
        CollectionRoute(:final collection) => switch (_body(params)) {
          final Map<String, Object?> body => await _save(
            '$collection:${_idOf(body)}',
            {...body, 'id': _idOf(body)},
            created: true,
          ),
          null => _badRequest(params.path),
        },
        FilesRoute() => switch (params.model) {
          final FileUpload upload => await _upload(upload),
          _ => _badRequest(params.path),
        },
        ItemRoute() || FileRoute() => _notAllowed(params.path),
        InvalidRoute() => _badRequest(params.path),
      };

  Future<ApiResult<Map<String, Object?>>> _put(Params<Object?> params) async =>
      switch (LocalRoute.parse(params.path)) {
        ItemRoute(:final key, :final id) => switch (_body(params)) {
          final Map<String, Object?> body => await _save(key, {
            ...body,
            'id': id,
          }),
          null => _badRequest(params.path),
        },
        CollectionRoute() ||
        FilesRoute() ||
        FileRoute() => _notAllowed(params.path),
        InvalidRoute() => _badRequest(params.path),
      };

  Future<ApiResult<Map<String, Object?>>> _patch(
    Params<Object?> params,
  ) async => switch (LocalRoute.parse(params.path)) {
    ItemRoute(:final key, :final id) => switch ((
      _store.read(key),
      _body(params),
    )) {
      (null, _) => _notFound(params.path),
      (_, null) => _badRequest(params.path),
      (final current?, final body?) => await _save(key, {
        ...current,
        ...body,
        'id': id,
      }),
    },
    CollectionRoute() ||
    FilesRoute() ||
    FileRoute() => _notAllowed(params.path),
    InvalidRoute() => _badRequest(params.path),
  };

  Future<ApiResult<Map<String, Object?>>> _delete(
    Params<Object?> params,
  ) async => switch (LocalRoute.parse(params.path)) {
    ItemRoute(:final key) => await _remove(key, params.path),
    FileRoute(:final key) => await _removeFile(key, params.path),
    CollectionRoute() || FilesRoute() => _notAllowed(params.path),
    InvalidRoute() => _badRequest(params.path),
  };

  Map<String, Object?>? _body(Params<Object?> params) => switch (params.body) {
    final Map<String, Object?> body => body,
    _ => null,
  };

  String _idOf(Map<String, Object?> body) => switch (body['id']) {
    final String id when RegExp(r'^[a-z0-9_-]{1,64}$').hasMatch(id) => id,
    _ => const Uuid().v4(),
  };

  Future<ApiResult<Map<String, Object?>>> _save(
    String key,
    Map<String, Object?> document, {
    bool created = false,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final stored = {
      ...document,
      'createdAt': _store.read(key)?['createdAt'] ?? now,
      'updatedAt': now,
    };
    final written = await _store.write(key, stored);
    return written.when(
      ok: (data) => _ok({'data': data}, status: created ? 201 : 200),
      err: (failure) => _fail(_storage(failure.message), 503),
    );
  }

  Future<ApiResult<Map<String, Object?>>> _remove(
    String key,
    String path,
  ) async {
    final removed = await _store.remove(key);
    return removed.when(
      ok: (existed) =>
          existed ? _ok(const {'data': null}, status: 200) : _notFound(path),
      err: (failure) => _fail(_storage(failure.message), 503),
    );
  }

  Future<ApiResult<Map<String, Object?>>> _upload(FileUpload upload) async {
    final saved = await _vault.save(
      bytes: upload.bytes,
      extension: upload.extension,
    );
    return saved.when(
      ok: (ref) => _save('files:${_fileIdOf(ref)}', {
        'id': _fileIdOf(ref),
        'ref': ref.value,
        'mime_type': upload.mimeType,
        'size': upload.bytes.length,
        'filename': upload.filename,
      }, created: true),
      err: (failure) async => _fail(_storage(failure.message), 503),
    );
  }

  Future<ApiResult<Map<String, Object?>>> _removeFile(
    String key,
    String path,
  ) async {
    final metadata = _store.read(key);
    if (metadata == null) {
      return _notFound(path);
    }
    if (StoredFileRef.parse(metadata['ref'] as String? ?? '')
        case final LocalFileRef ref) {
      final deleted = await _vault.delete(ref);
      if (deleted.errorOrNull case final FileVaultFailure failure) {
        return _fail(_storage(failure.message), 503);
      }
    }
    return _remove(key, path);
  }

  /// The file's name without extension, which is its uuid.
  static String _fileIdOf(LocalFileRef ref) {
    final name = ref.relativePath.split('/').last;
    final dot = name.indexOf('.');
    return dot < 0 ? name : name.substring(0, dot);
  }

  static ApiResult<Map<String, Object?>> _ok(
    Map<String, Object?> body, {
    int status = 200,
  }) => ApiResult.ok(body, statusCode: status);

  static ApiResult<Map<String, Object?>> _fail(ApiFailure error, int status) {
    Log.w('LocalApi ${error.title}: ${error.msm}');
    return ApiResult.err(error, statusCode: status);
  }

  static ApiResult<Map<String, Object?>> _notFound(String path) =>
      _fail(ApiErr(title: 'not_found', msm: 'Nothing at $path.'), 404);

  static ApiResult<Map<String, Object?>> _badRequest(String path) => _fail(
    ApiErr(title: 'bad_request', msm: 'Invalid request to $path.'),
    400,
  );

  static ApiResult<Map<String, Object?>> _notAllowed(String path) => _fail(
    ApiErr(title: 'method_not_allowed', msm: 'Not allowed on $path.'),
    405,
  );

  static ApiFailure _storage(String message) =>
      ApiErr(title: 'storage_unavailable', msm: message);
}
