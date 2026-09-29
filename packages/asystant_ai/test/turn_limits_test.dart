import 'package:asystant_ai/asystant_ai.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_flow_test.dart' show FakeTransport;

/// A model that never stops: every response proposes another tool call.
class _EndlessTransport extends FakeTransport {
  int requests = 0;

  @override
  Stream<InferenceEvent> infer({
    required List<AssistantMessage> messages,
    required String model,
    required String requestId,
    List<AsystantSystemPrompt> context = const [],
    List<ToolDefinition>? tools,
  }) async* {
    requests++;
    yield InferenceCompleted(
      AssistantMessage(
        role: MessageRole.assistant,
        content: '',
        calls: [
          ToolCall(
            id: 'call-$requests',
            name: 'look',
            arguments: const ToolArguments('{}'),
          ),
        ],
      ),
    );
  }
}

/// A read that runs without asking, so only the round limit stops the loop.
class _LookTool extends AsystantTool {
  int runs = 0;

  @override
  ToolDefinition get definition =>
      const ToolDefinition(name: 'look', description: 'Look', fields: []);

  @override
  bool get requiresConfirmation => false;

  @override
  Future<Result<AssistantCard, AssistantFailure>> preview(
    ToolArguments arguments,
  ) async => Ok(const AssistantCard(title: 'Looking'));

  @override
  Future<Result<ToolOutcome, AssistantFailure>> execute(
    ToolArguments arguments,
    ToolContext context,
  ) async {
    runs++;
    return Ok(const ToolOutcome(modelContent: 'Nothing new'));
  }
}

class _LoopingAssistant extends AsystantAI {
  _LoopingAssistant(this.look);

  final _LookTool look;

  @override
  List<AsystantTool> get tools => [look];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('maxRounds: 2 ends the turn at the second round', () async {
    final transport = _EndlessTransport();
    final look = _LookTool();
    final assistant = _LoopingAssistant(look)
      ..init(
        transport: transport,
        models: [AsystantModelOption.fallback('test')],
        turnLimits: const AsystantTurnLimits(maxRounds: 2),
      );

    await assistant.sendMessage('Keep looking');

    final state = assistant.conversation.notifier.state;
    expect(transport.requests, 2);
    expect(look.runs, 2);
    expect(state.phase, ChatPhase.error);
    expect(state.failure?.code, FailureCode.limit);
    assistant.dispose();
  });
}
