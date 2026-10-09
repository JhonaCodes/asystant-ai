import 'dart:convert';

import 'package:asystant_ai/asystant_ai.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_flow_test.dart' show settle;

/// Answers with [content] and no tool_calls, as a model that wrote a
/// presentation tool's arguments in plain text instead of calling it.
class TextOnlyTransport extends AssistantTransport {
  TextOnlyTransport(this.content);

  final String content;

  @override
  String? get identity => 'user-a';
  @override
  bool get isAuthenticated => true;
  @override
  Stream<void> get sessionChanges => const Stream.empty();
  @override
  Future<Result<List<String>, AssistantFailure>> initialize({
    required List<ToolDefinition> tools,
    required List<AsystantSystemPrompt> prompts,
    required List<String> models,
  }) async => Ok(models);
  @override
  Stream<InferenceEvent> infer({
    required List<AssistantMessage> messages,
    required String model,
    required String requestId,
    List<AsystantSystemPrompt> context = const [],
    List<ToolDefinition>? tools,
  }) async* {
    yield InferenceCompleted(
      AssistantMessage(role: MessageRole.assistant, content: content),
    );
  }

  @override
  void cancel() {}
  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'present_choices arguments written as plain text become its card',
    () async {
      final raw = jsonEncode({
        'question': '¿En qué entorno deseas consultar las aplicaciones registradas (loginflow)?',
        'options': ['DEV', 'PROD'],
        'context': 'El entorno determina si se consultan los datos de desarrollo o producción.',
      });
      final vm = ChatViewModel();
      await vm.configure(
        transport: TextOnlyTransport(raw),
        tools: AsystantPresentationRegistry(const [
          AsystantChoicesPresentation(),
        ]).tools,
        prompts: [],
        models: [AsystantModelOption.fallback('test')],
      );
      await vm.send('how many apps');
      await settle();

      // Redaction round-trips through the base AssistantCard.fromJson, same
      // as it does for a real tool_call to present_choices; the kind and
      // options are what identify it as the choices card. The turn ends on
      // this card (endsTurn: true), so its activity lands in a trailing
      // entry after it — same shape as a real present_choices tool_call.
      final card = vm.state.entries
          .map((entry) => entry.card)
          .firstWhere((card) => card != null, orElse: () => null);
      expect(card, isNotNull);
      expect(card?.kind, AssistantCardKind.selection);
      expect(card?.options, ['DEV', 'PROD']);
      expect(
        vm.state.entries.any((entry) => entry.message?.content == raw),
        isFalse,
        reason: 'the raw JSON must never reach the chat as text',
      );
      vm.dispose();
    },
  );

  test('text that does not validate against any registered presentation stays as text', () async {
    // Only one option: fails present_choices' 2-to-6-options rule.
    final raw = jsonEncode({
      'question': 'Pick one',
      'options': ['DEV'],
    });
    final vm = ChatViewModel();
    await vm.configure(
      transport: TextOnlyTransport(raw),
      tools: AsystantPresentationRegistry(const [AsystantChoicesPresentation()])
          .tools,
      prompts: [],
      models: [AsystantModelOption.fallback('test')],
    );
    await vm.send('how many apps');
    await settle();

    expect(vm.state.entries.last.message?.content, raw);
    expect(vm.state.entries.last.card, isNull);
    vm.dispose();
  });

  test(
    'JSON missing a required field stays as text instead of crashing the turn',
    () async {
      // No "question": fails the registry's generic schema check before
      // ever reaching present_choices' own validate().
      final raw = jsonEncode({
        'options': ['DEV', 'PROD'],
      });
      final vm = ChatViewModel();
      await vm.configure(
        transport: TextOnlyTransport(raw),
        tools: AsystantPresentationRegistry(const [
          AsystantChoicesPresentation(),
        ]).tools,
        prompts: [],
        models: [AsystantModelOption.fallback('test')],
      );
      await vm.send('how many apps');
      await settle();

      expect(vm.state.phase, isNot(ChatPhase.error));
      expect(vm.state.entries.last.message?.content, raw);
      expect(vm.state.entries.last.card, isNull);
      vm.dispose();
    },
  );

  test(
    'JSON with an extra unexpected field stays as text instead of losing it',
    () async {
      final raw = jsonEncode({
        'question': 'Pick one',
        'options': ['DEV', 'PROD'],
        'unexpected_field': 'gpt-oss added this',
      });
      final vm = ChatViewModel();
      await vm.configure(
        transport: TextOnlyTransport(raw),
        tools: AsystantPresentationRegistry(const [
          AsystantChoicesPresentation(),
        ]).tools,
        prompts: [],
        models: [AsystantModelOption.fallback('test')],
      );
      await vm.send('how many apps');
      await settle();

      expect(vm.state.entries.last.message?.content, raw);
      expect(vm.state.entries.last.card, isNull);
      vm.dispose();
    },
  );
}
