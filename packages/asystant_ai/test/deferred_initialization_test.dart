import 'dart:async';

import 'package:asystant_ai/asystant_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_flow_test.dart' show FakeTransport, settle;

class DeferredAssistant extends AsystantAI {
  int registrations = 0;

  @override
  List<AsystantTool> get tools {
    registrations++;
    return const [];
  }
}

class SlowTransport extends FakeTransport {
  int requests = 0;
  int disposals = 0;

  @override
  Future<void> dispose() async {
    disposals++;
    await super.dispose();
  }

  final response = Completer<Result<List<String>, AssistantFailure>>();

  @override
  Future<Result<List<String>, AssistantFailure>> initialize({
    required List<ToolDefinition> tools,
    required List<AsystantSystemPrompt> prompts,
    required List<String> models,
  }) {
    requests++;
    return response.future;
  }
}

class RetryTransport extends FakeTransport {
  int attempts = 0;

  @override
  Future<Result<List<String>, AssistantFailure>> initialize({
    required List<ToolDefinition> tools,
    required List<AsystantSystemPrompt> prompts,
    required List<String> models,
  }) async =>
      ++attempts == 1 ? Err(const AssistantFailure(.network)) : Ok(['test']);
}

class BrokenAssistant extends AsystantAI {
  @override
  List<AsystantTool> get tools => throw StateError('Host configuration failed');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launcher and host remain usable without starting a session', (
    tester,
  ) async {
    final assistant = DeferredAssistant();
    final transport = SlowTransport();
    assistant.init(transport: transport);
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextButton(
                onPressed: () => taps++,
                child: const Text('Host action'),
              ),
              AsystantButton(assistant: assistant),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Host action'));
    await tester.pump();
    expect(taps, 1);
    expect(assistant.registrations, 0);
    expect(transport.requests, 0);
    await tester.pumpWidget(const SizedBox());
    assistant.dispose();
  });

  testWidgets('an open chat paints while its session request is pending', (
    tester,
  ) async {
    final assistant = DeferredAssistant();
    final transport = SlowTransport();
    assistant.init(transport: transport);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsystantChat(
            assistant: assistant,
            strings: const AsystantStrings(spanish: false),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.text('Assistant'), findsOneWidget);
    expect(transport.requests, 1);
    expect(assistant.isInitialized, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    assistant.dispose();
    transport.response.complete(Err(const AssistantFailure(.network)));
    await tester.pump();
    expect(transport.disposals, 1);
  });

  test(
    'registration errors become assistant state, not unhandled exceptions',
    () async {
      final assistant = BrokenAssistant();
      final transport = SlowTransport();
      assistant.init(transport: transport);
      await assistant.ensureInitialized();
      expect(assistant.conversation.state.failure, isNotNull);
      expect(transport.requests, 0);
      assistant.dispose();
      await settle();
      expect(transport.disposals, 1);
    },
  );

  test('configuration cannot be silently replaced after setup', () async {
    final assistant = DeferredAssistant();
    final transport = SlowTransport();
    assistant.init(transport: transport);
    expect(() => assistant.init(transport: transport), throwsStateError);
    assistant.dispose();
    await settle();
    expect(transport.disposals, 1);
  });

  testWidgets('embedded chat retries failed setup without replaying a turn', (
    tester,
  ) async {
    final assistant = DeferredAssistant();
    final transport = RetryTransport();
    assistant.init(transport: transport);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsystantChat(
            assistant: assistant,
            strings: const AsystantStrings(spanish: false),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(assistant.conversation.state.failure, isNotNull);
    await tester.tap(find.text('Connect assistant'));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.runAsync(settle);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(
      transport.attempts,
      2,
      reason: assistant.conversation.state.phase.name,
    );
    expect(
      assistant.isInitialized,
      isTrue,
      reason: assistant.conversation.state.phase.name,
    );
    expect(assistant.conversation.state.messages, isEmpty);
    await tester.pumpWidget(const SizedBox());
    assistant.dispose();
  });

  test('concurrent opens share pending network initialization', () async {
    final assistant = DeferredAssistant();
    final transport = SlowTransport();
    assistant.init(transport: transport);
    final first = assistant.ensureInitialized();
    final second = assistant.ensureInitialized();
    expect(identical(first, second), isTrue);
    await settle();
    expect(assistant.registrations, 1);
    expect(transport.requests, 1);
    expect(assistant.isInitialized, isFalse);
    transport.response.complete(Ok(['test']));
    await first;
    expect(assistant.isInitialized, isTrue);
    await assistant.ensureInitialized();
    expect(transport.requests, 1);
    assistant.dispose();
  });

  test(
    'dispose before scheduled setup prevents tool registration and I/O',
    () async {
      final assistant = DeferredAssistant();
      final transport = SlowTransport();
      assistant.init(transport: transport);
      final pending = assistant.ensureInitialized();
      assistant.dispose();
      await pending;
      expect(assistant.registrations, 0);
      expect(transport.requests, 0);
    },
  );
}
