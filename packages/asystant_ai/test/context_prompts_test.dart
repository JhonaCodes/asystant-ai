import 'package:asystant_ai/asystant_ai.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_flow_test.dart' show FakeTransport, settle;

/// Remembers the context each model call received.
class _RecordingTransport extends FakeTransport {
  final List<List<String>> contexts = [];

  @override
  Stream<InferenceEvent> infer({
    required List<AssistantMessage> messages,
    required String model,
    required String requestId,
    List<AsystantSystemPrompt> context = const [],
  }) {
    contexts.add([for (final prompt in context) prompt.content]);
    return super.infer(
      messages: messages,
      model: model,
      requestId: requestId,
      context: context,
    );
  }
}

/// What the app knows about the person, as a tool would change it.
class _Memory {
  String allergy = 'none';
}

/// Saves what the person said without asking, like a profile tool.
class _SaveAllergy extends AsystantTool {
  _SaveAllergy(this.memory);

  final _Memory memory;

  @override
  bool get requiresConfirmation => false;

  @override
  ToolDefinition get definition =>
      const ToolDefinition(name: 'create', description: 'Save', fields: []);

  @override
  Future<Result<AssistantCard, AssistantFailure>> preview(
    ToolArguments arguments,
  ) async => Ok(const AssistantCard(title: 'Save'));

  @override
  Future<Result<ToolOutcome, AssistantFailure>> execute(
    ToolArguments arguments,
    ToolContext context,
  ) async {
    memory.allergy = 'pollen';
    return Ok(const ToolOutcome(modelContent: 'Saved'));
  }
}

class _Assistant extends AsystantAI {
  _Assistant(this.memory) : super(name: 'Assistant');

  final _Memory memory;

  @override
  List<AsystantTool> get tools => [_SaveAllergy(memory)];

  @override
  Future<List<AsystantSystemPrompt>> contextPrompts() async => [
    AsystantSystemPrompt(id: 'profile', content: 'Allergy: ${memory.allergy}'),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('what a tool saves reaches the very next model call', () async {
    final memory = _Memory();
    final transport = _RecordingTransport();
    final assistant = _Assistant(memory)
      ..init(
        transport: transport,
        models: [AsystantModelOption.fallback('test')],
      );
    await assistant.ensureInitialized();

    await assistant.sendMessage('I am allergic to pollen');
    await settle();

    expect(transport.contexts, [
      ['Allergy: none'],
      ['Allergy: pollen'],
    ]);
    assistant.dispose();
  });

  test('a context that breaks the prompt rules stops the turn', () async {
    final transport = _RecordingTransport();
    final assistant = _Duplicated()
      ..init(
        transport: transport,
        models: [AsystantModelOption.fallback('test')],
      );
    await assistant.ensureInitialized();

    await assistant.sendMessage('Hello');
    await settle();

    expect(transport.contexts, isEmpty);
    expect(
      assistant.conversation.notifier.state.failure?.code,
      FailureCode.protocol,
    );
    assistant.dispose();
  });
}

/// Sends two context prompts with the same id.
class _Duplicated extends AsystantAI {
  _Duplicated() : super(name: 'Assistant');

  @override
  List<AsystantTool> get tools => const [];

  @override
  Future<List<AsystantSystemPrompt>> contextPrompts() async => const [
    AsystantSystemPrompt(id: 'profile', content: 'Allergy: none'),
    AsystantSystemPrompt(id: 'profile', content: 'Allergy: pollen'),
  ];
}
