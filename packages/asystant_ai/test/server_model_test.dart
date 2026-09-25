import 'package:asystant_ai/src/viewmodel/chat_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_flow_test.dart' show FakeTransport;

class AssignedTransport extends FakeTransport {
  @override
  String? get defaultModel => 'large';
  @override
  bool get allowModelSelection => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'server default wins and a locked model cannot be changed from the SDK',
    () async {
      final vm = ChatViewModel();
      await vm.configure(
        transport: AssignedTransport(),
        tools: [],
        prompts: [],
        models: ['small', 'large'],
      );
      expect(vm.state.model, 'large');
      expect(vm.state.allowModelSelection, isFalse);
      vm.selectModel('small');
      expect(vm.state.model, 'large');
      vm.dispose();
    },
  );
}
