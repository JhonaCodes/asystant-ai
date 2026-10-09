import 'dart:typed_data';

import 'package:asystant_ai/asystant_ai.dart';
import 'package:asystant_ai/src/widgets/chat_conversation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_flow_test.dart' show FakeTransport;

/// Records the conversation each request receives.
class _RecordingTransport extends FakeTransport {
  final List<List<AssistantMessage>> received = [];

  @override
  Stream<InferenceEvent> infer({
    required List<AssistantMessage> messages,
    required String model,
    required String requestId,
    List<AsystantSystemPrompt> context = const [],
    List<ToolDefinition>? tools,
  }) {
    received.add(messages);
    return super.infer(
      messages: messages,
      model: model,
      requestId: requestId,
      context: context,
      tools: tools,
    );
  }
}

/// Returns a rendered frame for the model to look at.
class _LookTool extends AsystantTool {
  static final frame = AsystantAttachment.fromBytes(
    bytes: Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]),
    filename: 'frame.png',
  );

  @override
  ToolDefinition get definition =>
      const ToolDefinition(name: 'create', description: 'Look', fields: []);

  @override
  bool get requiresConfirmation => false;

  @override
  Future<Result<AssistantCard, AssistantFailure>> preview(
    ToolArguments arguments,
  ) async => Ok(const AssistantCard(title: 'Looking'));

  @override
  Future<Result<ToolOutcome, AssistantFailure>> execute(
    ToolArguments arguments,
    ToolContext context,
  ) async => Ok(ToolOutcome(modelContent: 'Rendered', images: [frame]));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the images a tool returns reach the next request on its result '
      'message', () async {
    final transport = _RecordingTransport();
    final vm = ChatViewModel();
    await vm.configure(
      transport: transport,
      tools: [_LookTool()],
      prompts: const [],
      models: [AsystantModelOption.fallback('test')],
    );

    await vm.send('Check the frame');

    expect(transport.received, hasLength(2));
    final result = transport.received.last.last;
    expect(result.role, MessageRole.tool);
    expect(result.callId, 'call-1');
    expect(result.content, 'Rendered');
    expect(result.attachments, [_LookTool.frame]);
    expect(result.attachments.single.bytes, _LookTool.frame.bytes);
    vm.dispose();
  });

  test('the completed step keeps the images, for the person to see', () async {
    final vm = ChatViewModel();
    await vm.configure(
      transport: _RecordingTransport(),
      tools: [_LookTool()],
      prompts: const [],
      models: [AsystantModelOption.fallback('test')],
    );

    await vm.send('Check the frame');

    final step = vm.state.entries.last.activity.single;
    expect(step.phase, StepPhase.completed);
    expect(step.images, [_LookTool.frame]);
    vm.dispose();
  });

  testWidgets('the chat shows the images of a step as thumbnails', (
    tester,
  ) async {
    final vm = ChatViewModel();
    final state = ChatState(
      entries: [
        ChatEntry(
          activity: [
            AssistantStep(
              id: 'turn/call-1',
              title: 'Rendered frame 12',
              phase: StepPhase.completed,
              images: [_LookTool.frame],
            ),
          ],
          message: const AssistantMessage(
            role: MessageRole.assistant,
            content: 'The frame looks right.',
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatConversation(
            name: 'Assistant',
            onStartNew: () {},
            state: state,
            viewModel: vm,
            strings: const AsystantStrings(spanish: false),
          ),
        ),
      ),
    );
    // A finished turn folds its steps; the person opens them to look.
    await tester.tap(find.text('1 step · completed'));
    await tester.pump();

    expect(find.bySemanticsLabel('frame.png'), findsOneWidget);
    vm.dispose();
  });
}
