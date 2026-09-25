import 'package:asystant_ai/asystant_ai.dart';
import 'package:asystant_ai/src/viewmodel/chat_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_flow_test.dart' show FakeTransport, WriteTool, settle;

class SelectionTool extends WriteTool {
  List<String> chosen = const [];
  @override
  bool get requiresSelection => true;
  @override
  Future<Result<AssistantCard, AssistantFailure>> preview(
    ToolArguments arguments,
  ) async => Ok(
    const AssistantCard(
      title: 'Choose activities',
      kind: AssistantCardKind.selection,
      options: ['experiment', 'journal'],
    ),
  );
  @override
  Future<Result<ToolOutcome, AssistantFailure>> execute(
    ToolArguments arguments,
    ToolContext context,
  ) async {
    chosen = context.selectedOptions;
    writes++;
    return Ok(
      const ToolOutcome(
        modelContent: 'created',
        card: AssistantCard(title: 'Result', kind: AssistantCardKind.result),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('selection must be explicit, uses only offered choices and keeps result before final answer', () async {
    final vm = ChatViewModel(), tool = SelectionTool();
    await vm.configure(
      transport: FakeTransport(),
      tools: [tool],
      prompts: [],
      models: ['test'],
    );
    final turn = vm.send('choose');
    await settle();
    vm.approve(true);
    await settle();
    expect(tool.writes, 0);
    vm.selectOption('injected');
    expect(vm.state.pending?.selected, isEmpty);
    vm.selectOption('journal');
    vm.approve(true);
    await turn;
    expect(tool.chosen, ['journal']);
    expect(tool.writes, 1);
    expect(vm.state.steps.single.phase, StepPhase.completed);
    expect(vm.state.entries[1].card?.title, 'Result');
    expect(vm.state.entries.last.message?.content, 'Done');
    vm.dispose();
  });
}
