import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asystant_ai/asystant_ai.dart';

import 'chat_flow_test.dart' show FakeTransport, WriteTool;

class BackgroundAssistant extends AsystantAI {
  BackgroundAssistant(this.localTools);

  final List<AsystantTool> localTools;

  @override
  List<AsystantTool> get tools => localTools;
}

class PendingReplyTransport extends FakeTransport {
  final reply = StreamController<InferenceEvent>();

  int requests = 0;

  int cancellations = 0;

  @override
  Stream<InferenceEvent> infer({
    required List<AssistantMessage> messages,
    required String model,
    required String requestId,
  }) {
    requests++;
    if (messages.last.role == MessageRole.tool) {
      return Stream.value(
        const InferenceCompleted(
          AssistantMessage(role: .assistant, content: 'Draft saved.'),
        ),
      );
    }
    return reply.stream;
  }

  @override
  void cancel() => cancellations++;

  @override
  Future<void> dispose() async {
    await reply.close();
    await super.dispose();
  }
}

class ConversationHost extends StatefulWidget {
  const ConversationHost({super.key, required this.assistant});

  final AsystantAI assistant;

  @override
  State<ConversationHost> createState() => ConversationHostState();
}

class ConversationHostState extends State<ConversationHost> {
  bool isChatVisible = true;

  int hostActions = 0;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () => setState(() => hostActions++),
            child: Text('Host actions: $hostActions'),
          ),
          TextButton(
            onPressed: () => setState(() => isChatVisible = true),
            child: const Text('Open chat'),
          ),
          if (isChatVisible)
            Expanded(
              child: AsystantChat(
                assistant: widget.assistant,
                strings: const AsystantStrings(spanish: false),
                onClose: () => setState(() => isChatVisible = false),
              ),
            ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets(
    'hidden chat receives its reply while host actions remain usable',
    (tester) async {
      final transport = PendingReplyTransport();
      final assistant = BackgroundAssistant([])
        ..init(transport: transport, models: ['test']);
      await tester.runAsync(assistant.ensureInitialized);
      await tester.pumpWidget(ConversationHost(assistant: assistant));
      final turn = assistant.conversation.notifier.send(
        'Summarize my workspace.',
      );
      await tester.pump();
      await tester.tap(find.text('Host actions: 0'));
      await tester.pump();
      expect(find.text('Host actions: 1'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      expect(find.byType(AsystantChat), findsNothing);
      await tester.tap(find.text('Host actions: 1'));
      await tester.pump();
      transport.reply.add(
        const InferenceCompleted(
          AssistantMessage(
            role: .assistant,
            content: 'Your workspace is ready.',
          ),
        ),
      );
      unawaited(transport.reply.close());
      await tester.pump();
      await turn;
      expect(assistant.conversation.state.phase, ChatPhase.done);
      expect(transport.cancellations, 0);
      expect(find.text('Host actions: 2'), findsOneWidget);
      await tester.tap(find.text('Open chat'));
      await tester.pump();
      expect(
        find.text('Your workspace is ready.', findRichText: true),
        findsOneWidget,
      );
      expect(
        transport.requests,
        1,
        reason: 'Reopening must not replay inference.',
      );
      await tester.pumpWidget(const SizedBox());
      assistant.dispose();
    },
  );

  testWidgets(
    'hidden approval waits and reopening does not duplicate a write',
    (tester) async {
      final transport = PendingReplyTransport();
      final tool = WriteTool();
      final assistant = BackgroundAssistant([tool])
        ..init(transport: transport, models: ['test']);
      await tester.runAsync(assistant.ensureInitialized);
      await tester.pumpWidget(ConversationHost(assistant: assistant));
      final turn = assistant.conversation.notifier.send('Create a draft.');
      await tester.pump();
      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      transport.reply.add(
        const InferenceCompleted(
          AssistantMessage(
            role: .assistant,
            content: '',
            calls: [
              ToolCall(
                id: 'create-draft',
                name: 'create',
                arguments: ToolArguments('{}'),
              ),
            ],
          ),
        ),
      );
      unawaited(transport.reply.close());
      await tester.pump();
      expect(assistant.conversation.state.phase, ChatPhase.permission);
      expect(tool.writes, 0);
      await tester.tap(find.text('Open chat'));
      await tester.pump();
      expect(find.text('Create draft', findRichText: true), findsWidgets);
      assistant.conversation.notifier.approve(true);
      await tester.pump();
      await turn;
      expect(tool.writes, 1);
      expect(assistant.conversation.state.phase, ChatPhase.done);
      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      await tester.tap(find.text('Open chat'));
      await tester.pump();
      expect(tool.writes, 1);
      expect(transport.requests, 2);
      await tester.pumpWidget(const SizedBox());
      assistant.dispose();
    },
  );

  testWidgets('hidden account change discards queued and late response text', (
    tester,
  ) async {
    final transport = PendingReplyTransport();
    final assistant = BackgroundAssistant([])
      ..init(transport: transport, models: ['test']);
    await tester.runAsync(assistant.ensureInitialized);
    await tester.pumpWidget(ConversationHost(assistant: assistant));
    final turn = assistant.conversation.notifier.send('Read private settings.');
    await tester.pump();
    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
    transport.reply.add(const TextDelta('Previous account settings'));
    await tester.pump();
    transport.currentIdentity = 'user-b';
    transport.changes.add(null);
    transport.reply.add(
      const InferenceCompleted(
        AssistantMessage(role: .assistant, content: 'Private old response'),
      ),
    );
    unawaited(transport.reply.close());
    await tester.pump(const Duration(milliseconds: 40));
    await tester.runAsync(() => turn);
    expect(assistant.conversation.state.streaming, isEmpty);
    expect(assistant.conversation.state.messages, isEmpty);
    expect(assistant.conversation.state.entries, isEmpty);
    expect(assistant.isInitialized, isFalse);
    await tester.pumpWidget(const SizedBox());
    assistant.dispose();
  });

  testWidgets(
    'stream bursts are batched and cancellation clears scheduled text',
    (tester) async {
      final transport = PendingReplyTransport();
      final assistant = BackgroundAssistant([])
        ..init(transport: transport, models: ['test']);
      await tester.runAsync(assistant.ensureInitialized);
      final viewModel = assistant.conversation.notifier;
      var notifications = 0;
      void countNotifications() => notifications++;
      viewModel.addListener(countNotifications);
      final turn = viewModel.send('Read a long response.');
      await tester.pump();
      notifications = 0;
      for (var index = 0; index < 200; index++) {
        transport.reply.add(const TextDelta('word '));
      }
      await tester.pump();
      expect(
        notifications,
        lessThan(10),
        reason: 'A token burst must not rebuild the host per token.',
      );
      await tester.pump(const Duration(milliseconds: 40));
      expect(viewModel.state.streaming, List.filled(200, 'word ').join());
      transport.reply.add(const TextDelta('late text'));
      await tester.pump();
      viewModel.cancel();
      unawaited(transport.reply.close());
      await tester.pump(const Duration(milliseconds: 40));
      await turn;
      expect(viewModel.state.phase, ChatPhase.canceled);
      expect(viewModel.state.streaming, isEmpty);
      viewModel.removeListener(countNotifications);
      assistant.dispose();
    },
  );
}
