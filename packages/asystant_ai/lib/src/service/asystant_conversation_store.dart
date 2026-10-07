import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/model/conversation_snapshot.dart';
import 'package:asystant_ai/src/model/conversation_summary.dart';

/// Keeps the conversations that are not on screen, per signed-in identity.
///
/// Implement it to persist conversations (a local database, secure storage);
/// the default [InMemoryConversationStore] forgets them when the app closes.
/// [scope] is the transport identity, so one user never reads another's.
abstract class AsystantConversationStore {
  const AsystantConversationStore();

  Future<Result<List<ConversationSummary>, AssistantFailure>> list(
    String scope,
  );

  Future<Result<ConversationSnapshot, AssistantFailure>> read(
    String scope,
    String id,
  );

  Future<Result<bool, AssistantFailure>> write(
    String scope,
    ConversationSnapshot snapshot,
  );

  Future<Result<bool, AssistantFailure>> delete(String scope, String id);

  /// Forgets every conversation of [scope], for example on sign-out.
  Future<Result<bool, AssistantFailure>> clear(String scope);

  /// The conversation last shown for this identity, including an empty one.
  Future<Result<String?, AssistantFailure>> activeId(String scope) async =>
      Ok(null);

  Future<Result<bool, AssistantFailure>> setActiveId(
    String scope,
    String id,
  ) async => Ok(true);
}

/// Conversations kept while the app runs.
class InMemoryConversationStore extends AsystantConversationStore {
  InMemoryConversationStore();

  final Map<String, Map<String, ConversationSnapshot>> _scopes = {};
  final Map<String, String> _active = {};

  @override
  Future<Result<String?, AssistantFailure>> activeId(String scope) async =>
      Ok(_active[scope]);

  @override
  Future<Result<bool, AssistantFailure>> setActiveId(
    String scope,
    String id,
  ) async {
    _active[scope] = id;
    return Ok(true);
  }

  @override
  Future<Result<List<ConversationSummary>, AssistantFailure>> list(
    String scope,
  ) async => Ok(
    List.unmodifiable([
      for (final snapshot in (_scopes[scope] ?? const {}).values)
        snapshot.summary,
    ]),
  );

  @override
  Future<Result<ConversationSnapshot, AssistantFailure>> read(
    String scope,
    String id,
  ) async => switch (_scopes[scope]?[id]) {
    final ConversationSnapshot snapshot => Ok(snapshot),
    null => Err(const AssistantFailure(.unavailable)),
  };

  @override
  Future<Result<bool, AssistantFailure>> write(
    String scope,
    ConversationSnapshot snapshot,
  ) async {
    (_scopes[scope] ??= {})[snapshot.summary.id] = snapshot;
    return Ok(true);
  }

  @override
  Future<Result<bool, AssistantFailure>> delete(
    String scope,
    String id,
  ) async => Ok(_scopes[scope]?.remove(id) != null);

  @override
  Future<Result<bool, AssistantFailure>> clear(String scope) async {
    _active.remove(scope);
    return Ok(_scopes.remove(scope) != null);
  }
}
