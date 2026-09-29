import 'package:asystant_ai/asystant_ai.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_flow_test.dart' show FakeTransport, WriteTool, settle;

/// A host setting the person can flip while the chat is open.
class _Settings {
  bool approvesAll = false;
}

/// Asks before [WriteTool] runs unless the host's switch approves everything.
class _Assistant extends AsystantAI {
  _Assistant(this.settings, this.write) : super(name: 'Assistant');

  final _Settings settings;

  final WriteTool write;

  @override
  List<AsystantTool> get tools => [write];

  @override
  bool requiresConfirmation(AsystantTool tool) =>
      !settings.approvesAll && tool.requiresConfirmation;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the confirmation policy is asked again on every call', () async {
    final settings = _Settings()..approvesAll = true;
    final write = WriteTool();
    final assistant = _Assistant(settings, write)
      ..init(
        transport: FakeTransport(),
        models: [AsystantModelOption.fallback('test')],
      );
    await assistant.ensureInitialized();
    final chat = assistant.conversation.notifier;

    final approved = assistant.sendMessage('create');
    await settle();
    expect(write.writes, 1);
    await approved;
    expect(chat.state.phase, ChatPhase.done);

    settings.approvesAll = false;
    final turn = assistant.sendMessage('create again');
    await settle();
    expect(chat.state.phase, ChatPhase.permission);
    expect(write.writes, 1);
    chat.approve(false);
    await turn;
    expect(write.writes, 1);

    assistant.dispose();
  });
}
