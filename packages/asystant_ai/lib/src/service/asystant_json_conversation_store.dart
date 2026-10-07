import 'dart:async';
import 'dart:convert';

import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/model/conversation_snapshot.dart';
import 'package:asystant_ai/src/model/conversation_summary.dart';
import 'package:asystant_ai/src/service/asystant_conversation_store.dart';

/// Persists complete conversations through the host's string key/value store.
/// Reads and writes are serialized so overlapping turn updates cannot replace
/// a newer snapshot with an older one.
class AsystantJsonConversationStore extends AsystantConversationStore {
  AsystantJsonConversationStore({
    required this.readValue,
    required this.writeValue,
    required this.removeValue,
    this.keyPrefix = 'asystant_ai.conversations.v1',
  });

  final Future<String?> Function(String key) readValue;
  final Future<bool> Function(String key, String value) writeValue;
  final Future<bool> Function(String key) removeValue;
  final String keyPrefix;

  Future<void> _tail = Future.value();

  String _key(String scope) =>
      '$keyPrefix.${base64Url.encode(utf8.encode(scope))}';

  Future<Result<T, AssistantFailure>> _run<T>(
    Future<Result<T, AssistantFailure>> Function() operation,
  ) async {
    final previous = _tail;
    final done = Completer<void>();
    _tail = done.future;
    await previous;
    try {
      return await operation();
    } catch (_) {
      return Err(const AssistantFailure(.unavailable));
    } finally {
      done.complete();
    }
  }

  Future<_ConversationDocument> _read(String scope) async {
    final raw = await readValue(_key(scope));
    if (raw == null) return _ConversationDocument();
    final json = (jsonDecode(raw) as Map).cast<String, Object?>();
    if (json['version'] != 1) throw const FormatException('Version');
    return _ConversationDocument(
      active: json['active'] as String?,
      snapshots: {
        for (final entry in (json['conversations'] as Map).entries)
          entry.key as String: ConversationSnapshot.fromJson(
            (entry.value as Map).cast<String, Object?>(),
          ),
      },
    );
  }

  Future<Result<bool, AssistantFailure>> _write(
    String scope,
    _ConversationDocument document,
  ) async {
    final saved = await writeValue(
      _key(scope),
      jsonEncode({
        'version': 1,
        'active': document.active,
        'conversations': {
          for (final entry in document.snapshots.entries)
            entry.key: entry.value.toJson(),
        },
      }),
    );
    return saved ? Ok(true) : Err(AssistantFailure(.unavailable));
  }

  @override
  Future<Result<List<ConversationSummary>, AssistantFailure>> list(
    String scope,
  ) => _run(() async {
    final document = await _read(scope);
    return Ok(
      List.unmodifiable([
        for (final snapshot in document.snapshots.values) snapshot.summary,
      ]),
    );
  });

  @override
  Future<Result<ConversationSnapshot, AssistantFailure>> read(
    String scope,
    String id,
  ) => _run(() async {
    final snapshot = (await _read(scope)).snapshots[id];
    return snapshot == null
        ? Err(AssistantFailure(.unavailable))
        : Ok(snapshot);
  });

  @override
  Future<Result<bool, AssistantFailure>> write(
    String scope,
    ConversationSnapshot snapshot,
  ) => _run(() async {
    final document = await _read(scope);
    document.snapshots[snapshot.summary.id] = snapshot;
    return _write(scope, document);
  });

  @override
  Future<Result<bool, AssistantFailure>> delete(String scope, String id) =>
      _run(() async {
        final document = await _read(scope);
        document.snapshots.remove(id);
        if (document.active == id) document.active = null;
        return _write(scope, document);
      });

  @override
  Future<Result<bool, AssistantFailure>> clear(String scope) => _run(
    () async => await removeValue(_key(scope))
        ? Ok(true)
        : Err(AssistantFailure(.unavailable)),
  );

  @override
  Future<Result<String?, AssistantFailure>> activeId(String scope) =>
      _run(() async => Ok((await _read(scope)).active));

  @override
  Future<Result<bool, AssistantFailure>> setActiveId(String scope, String id) =>
      _run(() async {
        final document = await _read(scope);
        document.active = id;
        return _write(scope, document);
      });
}

class _ConversationDocument {
  _ConversationDocument({
    this.active,
    Map<String, ConversationSnapshot>? snapshots,
  }) : snapshots = snapshots ?? {};

  String? active;
  final Map<String, ConversationSnapshot> snapshots;
}
