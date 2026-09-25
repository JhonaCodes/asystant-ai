import 'dart:async';

import 'package:asystant_ai/asystant_ai.dart';
import 'package:asystant_ai/src/viewmodel/chat_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTransport extends AssistantTransport {
  final changes = StreamController<void>.broadcast(sync: true);
  String? currentIdentity = 'user-a';
  @override
  String? get identity => currentIdentity;
  @override
  bool get isAuthenticated => identity != null;
  @override
  Stream<void> get sessionChanges => changes.stream;
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
  }) async* {
    if (messages.last.role == MessageRole.user) {
      yield const InferenceCompleted(
        AssistantMessage(
          role: MessageRole.assistant,
          content: '',
          calls: [
            ToolCall(
              id: 'call-1',
              name: 'create',
              arguments: ToolArguments('{}'),
            ),
          ],
        ),
      );
    } else {
      yield const InferenceCompleted(
        AssistantMessage(role: MessageRole.assistant, content: 'Done'),
      );
    }
  }

  @override
  void cancel() {}
  @override
  Future<void> dispose() async => changes.close();
}

class WriteTool extends AsystantTool {
  int writes = 0;
  @override
  ToolDefinition get definition => const ToolDefinition(
    name: 'create',
    description: 'Create draft',
    fields: [],
  );
  @override
  Future<Result<AssistantCard, AssistantFailure>> preview(
    ToolArguments arguments,
  ) async => Ok(
    const AssistantCard(
      title: 'Create draft',
      kind: AssistantCardKind.permission,
    ),
  );
  @override
  Future<Result<ToolOutcome, AssistantFailure>> execute(
    ToolArguments arguments,
    ToolContext context,
  ) async {
    context.checkCanceled();
    writes++;
    return Ok(const ToolOutcome(modelContent: 'Created'));
  }
}

Future<void> settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'writes require one explicit approval and double submit cannot duplicate',
    () async {
      final vm = ChatViewModel(),
          transport = FakeTransport(),
          tool = WriteTool();
      await vm.configure(
        transport: transport,
        tools: [tool],
        prompts: [],
        models: ['test'],
      );
      final turn = vm.send('create');
      await settle();
      expect(vm.state.phase, ChatPhase.permission);
      expect(vm.state.steps.single.phase, StepPhase.permission);
      expect(tool.writes, 0);
      await vm.send('duplicate');
      vm.approve(true);
      vm.approve(true);
      await turn;
      expect(tool.writes, 1);
      expect(vm.state.phase, ChatPhase.done);
      expect(vm.state.steps.single.phase, StepPhase.completed);
      vm.dispose();
    },
  );
  test('denial and session changes never execute pending tools', () async {
    for (final changeSession in [false, true]) {
      final vm = ChatViewModel(),
          transport = FakeTransport(),
          tool = WriteTool();
      await vm.configure(
        transport: transport,
        tools: [tool],
        prompts: [],
        models: ['test'],
      );
      final turn = vm.send('create');
      await settle();
      if (changeSession) {
        transport.currentIdentity = 'user-b';
        transport.changes.add(null);
      } else {
        vm.approve(false);
      }
      await turn;
      expect(tool.writes, 0);
      if (changeSession) {
        expect(vm.state.messages, isEmpty);
        expect(vm.isInitialized, isFalse);
      }
      vm.dispose();
    }
  });
  test('cancel while awaiting permission clears it', () async {
    final vm = ChatViewModel(), transport = FakeTransport(), tool = WriteTool();
    await vm.configure(
      transport: transport,
      tools: [tool],
      prompts: [],
      models: ['test'],
    );
    final turn = vm.send('create');
    await settle();
    vm.cancel();
    vm.approve(true);
    await turn;
    expect(tool.writes, 0);
    expect(vm.state.pending, isNull);
    expect(vm.state.phase, ChatPhase.canceled);
    expect(
      vm.state.messages.where((m) => m.role == MessageRole.tool).length,
      1,
      reason:
          'canceled tool calls must have a terminal result before next send',
    );
    vm.dispose();
  });
}
