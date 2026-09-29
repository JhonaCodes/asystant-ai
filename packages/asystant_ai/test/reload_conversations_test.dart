import 'package:flutter_test/flutter_test.dart';

import 'package:asystant_ai/asystant_ai.dart';

import 'chat_flow_test.dart' show FakeTransport;

class _Assistant extends AsystantAI {
  _Assistant() : super(name: 'Studio');

  @override
  List<AsystantTool> get tools => const [];
}

/// A store with one list per open document, like a host that keeps the
/// conversations inside each document.
class _DocumentStore extends InMemoryConversationStore {
  String document = 'chapter-1';

  final Map<String, List<ConversationSummary>> saved = {};

  final List<String> written = [];

  @override
  Future<Result<List<ConversationSummary>, AssistantFailure>> list(
    String scope,
  ) async => Ok(saved[document] ?? const []);

  @override
  Future<Result<ConversationSnapshot, AssistantFailure>> read(
    String scope,
    String id,
  ) async => Ok(
    ConversationSnapshot(
      summary: saved[document]!.firstWhere((summary) => summary.id == id),
    ),
  );

  @override
  Future<Result<bool, AssistantFailure>> write(
    String scope,
    ConversationSnapshot snapshot,
  ) async {
    written.add(snapshot.summary.id);
    return Ok(true);
  }
}

ConversationSummary _summary(String id, int minute) => ConversationSummary(
  id: id,
  title: 'About $id',
  model: 'test',
  createdAt: DateTime.utc(2026, 9, 30, 10),
  updatedAt: DateTime.utc(2026, 9, 30, 10, minute),
);

void main() {
  test('reloading replaces the list with what the store answers now, newest '
      'first, after keeping the conversation on screen', () async {
    final store = _DocumentStore()
      ..saved['chapter-1'] = [_summary('intro', 1)]
      ..saved['chapter-2'] = [_summary('old', 1), _summary('recent', 2)];
    final assistant = _Assistant()
      ..init(
        transport: FakeTransport(),
        models: [AsystantModelOption.fallback('test')],
        conversationStore: store,
      );
    addTearDown(assistant.dispose);
    await assistant.ensureInitialized();
    final chat = assistant.conversation.notifier;
    await chat.openConversation('intro');
    expect(chat.state.conversations.map((summary) => summary.id), ['intro']);

    store.document = 'chapter-2';
    await chat.reloadConversations();

    expect(chat.state.conversations.map((summary) => summary.id), [
      'recent',
      'old',
    ]);
    // The one on screen was kept before the list changed, and it stays on
    // screen until the host opens another.
    expect(store.written, ['intro']);
    expect(chat.state.conversationId, 'intro');
  });
}
