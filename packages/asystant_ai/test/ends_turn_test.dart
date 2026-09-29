import 'package:asystant_ai/asystant_ai.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_flow_test.dart' show FakeTransport;

/// Proposes an approval request and a write in the same response, and
/// records what each request could call.
class _GateTransport extends FakeTransport {
  int requests = 0;

  final List<List<String>> offered = [];

  @override
  Stream<InferenceEvent> infer({
    required List<AssistantMessage> messages,
    required String model,
    required String requestId,
    List<AsystantSystemPrompt> context = const [],
    List<ToolDefinition>? tools,
  }) async* {
    requests++;
    offered.add([
      for (final tool in tools ?? const <ToolDefinition>[]) tool.name,
    ]);
    yield const InferenceCompleted(
      AssistantMessage(
        role: MessageRole.assistant,
        content: 'I need your approval first.',
        calls: [
          ToolCall(
            id: 'call-gate',
            name: 'request_approval',
            arguments: ToolArguments('{}'),
          ),
          ToolCall(
            id: 'call-write',
            name: 'create',
            arguments: ToolArguments('{}'),
          ),
        ],
      ),
    );
  }
}

class _ApprovalTool extends AsystantTool {
  @override
  ToolDefinition get definition => const ToolDefinition(
    name: 'request_approval',
    description: 'Ask the person to approve',
    fields: [],
  );

  @override
  bool get requiresConfirmation => false;

  @override
  Future<Result<AssistantCard, AssistantFailure>> preview(
    ToolArguments arguments,
  ) async => Ok(const AssistantCard(title: 'Asking'));

  @override
  Future<Result<ToolOutcome, AssistantFailure>> execute(
    ToolArguments arguments,
    ToolContext context,
  ) async => Ok(
    const ToolOutcome(
      modelContent: 'Waiting for the person.',
      summary: 'Asked for approval',
      data: {'gate': 'final_cut'},
      endsTurn: true,
    ),
  );
}

/// A write that runs without asking, so only the end of the turn stops it.
class _CountingTool extends _ApprovalTool {
  int runs = 0;

  @override
  ToolDefinition get definition =>
      const ToolDefinition(name: 'create', description: 'Create', fields: []);

  @override
  Future<Result<ToolOutcome, AssistantFailure>> execute(
    ToolArguments arguments,
    ToolContext context,
  ) async {
    runs++;
    return Ok(const ToolOutcome(modelContent: 'Created'));
  }
}

class _HiddenTool extends _ApprovalTool {
  @override
  ToolDefinition get definition =>
      const ToolDefinition(name: 'hidden', description: 'Hidden', fields: []);

  @override
  bool get isAvailable => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a tool that ends the turn stops the loop before the next call',
    () async {
      final transport = _GateTransport();
      final write = _CountingTool();
      final vm = ChatViewModel();
      await vm.configure(
        transport: transport,
        tools: [_ApprovalTool(), write, _HiddenTool()],
        prompts: const [],
        models: [AsystantModelOption.fallback('test')],
      );

      await vm.send('Export it');

      expect(transport.requests, 1);
      expect(transport.offered.single, ['request_approval', 'create']);
      expect(write.runs, 0);
      expect(vm.state.phase, ChatPhase.done);
      expect(vm.state.pending, isNull);
      expect(vm.state.steps, isEmpty);
      final step = vm.state.entries.last.activity.single;
      expect(step.title, 'Asked for approval');
      expect(step.toolName, 'request_approval');
      expect(step.startedAt, isNotNull);
      expect(step.data, {'gate': 'final_cut'});
      expect(
        [
          for (final message in vm.state.messages)
            if (message.role == MessageRole.tool) message.callId,
        ],
        ['call-gate', 'call-write'],
      );
      vm.dispose();
    },
  );
}
