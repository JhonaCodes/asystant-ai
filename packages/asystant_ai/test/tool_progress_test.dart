import 'dart:async';

import 'package:asystant_ai/asystant_ai.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_flow_test.dart' show FakeTransport;

/// A long tool that reports progress twice, waits until the test releases
/// it, and reports once more before it returns.
class _LongTool extends AsystantTool {
  final release = Completer<void>();

  final running = Completer<void>();

  bool? canceledWhenReleased;

  @override
  ToolDefinition get definition =>
      const ToolDefinition(name: 'create', description: 'Render', fields: []);

  @override
  bool get requiresConfirmation => false;

  @override
  Future<Result<AssistantCard, AssistantFailure>> preview(
    ToolArguments arguments,
  ) async => Ok(const AssistantCard(title: 'Rendering'));

  @override
  Future<Result<ToolOutcome, AssistantFailure>> execute(
    ToolArguments arguments,
    ToolContext context,
  ) async {
    context.reportProgress(0.1, label: 'Frame 1 of 10');
    context.reportProgress(0.5, label: 'Frame 5 of 10');
    running.complete();
    await release.future;
    canceledWhenReleased = context.isCanceled;
    context.reportProgress(0.9, label: 'Frame 9 of 10');
    return Err(const AssistantFailure(.canceled));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('progress reaches the running step, and cancel reaches the tool '
      'and leaves the step canceled', () async {
    final tool = _LongTool();
    final vm = ChatViewModel();
    await vm.configure(
      transport: FakeTransport(),
      tools: [tool],
      prompts: const [],
      models: [AsystantModelOption.fallback('test')],
    );

    final turn = vm.send('Render it');
    await tool.running.future;

    // The first report shows at once; the second, once the interval ends.
    expect(vm.state.steps.single.progress, 0.1);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final running = vm.state.steps.single;
    expect(running.phase, StepPhase.running);
    expect(running.showsProgress, isTrue);
    expect(running.progress, 0.5);
    expect(running.progressLabel, 'Frame 5 of 10');

    vm.cancel();
    tool.release.complete();
    await turn;
    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(tool.canceledWhenReleased, isTrue);
    expect(vm.state.phase, ChatPhase.canceled);
    expect(vm.state.steps, isEmpty);
    final step = vm.state.entries.last.activity.single;
    expect(step.phase, StepPhase.canceled);
    expect(step.showsProgress, isFalse);
    // The report after cancel is ignored.
    expect(step.progress, 0.5);
    vm.dispose();
  });
}
