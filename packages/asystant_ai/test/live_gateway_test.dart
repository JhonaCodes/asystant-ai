import 'dart:io';

import 'package:asystant_ai/asystant_ai.dart';
import 'package:asystant_ai/src/viewmodel/chat_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_flow_test.dart' show WriteTool;

/// Opt-in paid smoke test. Tokens are injected through environment, never logged.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'real OpenRouter proposes a local tool, awaits approval and completes',
    () async {
      final previousHttpOverride = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previousHttpOverride);
      final gateway = Platform.environment['ASYSTANT_LIVE_GATEWAY']!;
      final ticket = Platform.environment['ASYSTANT_LIVE_TICKET']!;
      final session = CallbackSessionSource(
        identity: () => 'live-smoke-session',
        changes: const Stream.empty(),
        issueTicket: () async => Ok(ticket),
      );
      final transport = GatewayTransport(
        baseUri: Uri.parse(gateway),
        sessionSource: session,
      );
      final vm = ChatViewModel();
      final tool = WriteTool();
      await vm.configure(
        transport: transport,
        tools: [tool],
        prompts: const [
          AsystantSystemPrompt(
            id: 'test',
            content: 'You are testing a local app tool. For the user request, call the create tool exactly once with empty arguments. After its result, reply briefly in Spanish. Never claim a write occurred before the tool result.',
          ),
        ],
        models: ['openai/gpt-oss-20b'],
      );
      expect(vm.isInitialized, isTrue);
      final turn = vm.send('Crea un borrador usando create una sola vez.');
      final deadline = DateTime.now().add(const Duration(seconds: 100));
      while (vm.state.phase != ChatPhase.permission &&
          vm.state.phase != ChatPhase.error &&
          vm.state.phase != ChatPhase.done &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(
        vm.state.phase,
        ChatPhase.permission,
        reason: 'The real model must propose a registered tool',
      );
      expect(tool.writes, 0);
      vm.approve(true);
      await turn.timeout(const Duration(seconds: 100));
      expect(tool.writes, 1);
      expect(vm.state.phase, ChatPhase.done);
      expect(vm.state.messages.last.content, isNotEmpty);
      final revoked = await transport.revokeSession();
      expect(revoked.isOk, isTrue);
      vm.dispose();
    },
    skip: Platform.environment['ASYSTANT_LIVE_GATEWAY'] == null,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
