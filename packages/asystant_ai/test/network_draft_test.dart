import 'package:asystant_ai/asystant_ai.dart';
import 'package:asystant_ai/src/viewmodel/chat_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_flow_test.dart' show FakeTransport;

class OfflineTransport extends FakeTransport {
  @override
  Stream<InferenceEvent> infer({
    required List<AssistantMessage> messages,
    required String model,
    required String requestId,
  }) async* {
    yield const InferenceFailed(AssistantFailure(FailureCode.network));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('network failure before any result preserves the unsent draft without replay', () async {
    final vm = ChatViewModel();
    await vm.configure(
      transport: OfflineTransport(),
      tools: [],
      prompts: [],
      models: ['test'],
    );
    await vm.send('Preparar una clase');
    expect(vm.state.draft, 'Preparar una clase');
    expect(vm.state.phase, ChatPhase.error);
    expect(vm.state.messages.length, 1);
    expect(vm.state.steps, isEmpty);
    vm.dispose();
  });
}
