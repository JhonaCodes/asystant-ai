import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logger_rs/logger_rs.dart';
import 'package:result_controller/result_controller.dart';

import 'package:host_app/src/integrations/local_db/local_db.dart';

/// Loads the bundled catalog into the local database, once per version.
///
/// Documents are written with `origin: seed`. A newer seed replaces the old
/// seed documents and removes the ones it no longer carries; documents the
/// person added (`origin: person`) are never touched. The ledger is written
/// last, so a start interrupted halfway simply runs the seed again.
abstract final class LocalSeed {
  static const asset = 'assets/seed/botanica_seed.json';

  /// One file per plant, named by its id; the seed lists the ids.
  static const plantsFolder = 'assets/seed/plants/';

  static const _ledgerKey = 'meta:seed';

  static Future<Result<bool, LocalStoreFailure>> apply(LocalStore store) async {
    try {
      return await _apply(store);
    } on TypeError catch (error, stackTrace) {
      // A seed that does not have the expected shape is skipped, not fatal.
      Log.e(
        'Seed has an unexpected shape',
        error: error,
        stackTrace: stackTrace,
      );
      return Ok(false);
    }
  }

  static Future<Result<bool, LocalStoreFailure>> _apply(
    LocalStore store,
  ) async {
    final Map<String, Object?> seed;
    try {
      seed = jsonDecode(
        await rootBundle.loadString(asset),
      ) as Map<String, Object?>;
    } on FlutterError catch (error, stackTrace) {
      Log.e('Seed asset missing', error: error, stackTrace: stackTrace);
      return Ok(false);
    } on FormatException catch (error, stackTrace) {
      Log.e(
        'Seed asset is not valid JSON',
        error: error,
        stackTrace: stackTrace,
      );
      return Ok(false);
    }
    final version = seed['version'] as int? ?? 0;
    final ledger = store.read(_ledgerKey);
    if ((ledger?['version'] as int? ?? 0) >= version) {
      return Ok(true);
    }
    final documents = <String, Map<String, Object?>>{
      if (seed['reference'] case final Map<String, Object?> reference)
        'reference:${reference['id']}': reference,
      for (final id
          in (seed['plants'] as List<Object?>? ?? const []).whereType<String>())
        'plants:$id': jsonDecode(
          await rootBundle.loadString('$plantsFolder$id.json'),
        ) as Map<String, Object?>,
    };
    final now = DateTime.now().toUtc().toIso8601String();
    for (final MapEntry(key: key, value: document) in documents.entries) {
      if (store.read(key)?['origin'] == 'person') {
        continue;
      }
      final written = await store.write(key, {
        ...document,
        'origin': 'seed',
        'seedVersion': version,
        'createdAt': store.read(key)?['createdAt'] ?? now,
        'updatedAt': now,
      });
      if (written.errorOrNull case final LocalStoreFailure failure) {
        return Err(failure);
      }
    }
    final previous = (ledger?['keys'] as List<Object?>? ?? const [])
        .whereType<String>();
    for (final stale in previous.where((key) => !documents.containsKey(key))) {
      if (store.read(stale)?['origin'] == 'seed') {
        await store.remove(stale);
      }
    }
    final saved = await store.write(_ledgerKey, {
      'version': version,
      'keys': documents.keys.toList(),
      'appliedAt': now,
    });
    Log.i('Seed v$version applied: ${documents.length} documents');
    return saved.when(ok: (_) => Ok(true), err: Err.new);
  }
}
