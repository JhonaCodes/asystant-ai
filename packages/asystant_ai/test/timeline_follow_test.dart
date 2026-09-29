import 'package:asystant_ai/asystant_ai.dart';
import 'package:asystant_ai/src/widgets/chat_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_flow_test.dart' show FakeTransport;

/// Answers every message with a reply taller than the screen.
class _LongReplyTransport extends FakeTransport {
  @override
  Stream<InferenceEvent> infer({
    required List<AssistantMessage> messages,
    required String model,
    required String requestId,
    List<AsystantSystemPrompt> context = const [],
    List<ToolDefinition>? tools,
  }) async* {
    yield InferenceCompleted(
      AssistantMessage(
        role: MessageRole.assistant,
        content: [for (var line = 1; line <= 30; line++) 'Line $line']
            .join('\n\n'),
      ),
    );
  }
}

class _Assistant extends AsystantAI {
  _Assistant() : super(name: 'Assistant');

  @override
  List<AsystantTool> get tools => const [];
}

Future<_Assistant> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final assistant = _Assistant()
    ..init(
      transport: _LongReplyTransport(),
      models: [AsystantModelOption.fallback('test')],
    );
  await tester.runAsync(assistant.ensureInitialized);
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
  await tester.pumpAndSettle();
  return assistant;
}

Future<void> _send(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.byTooltip('Send'));
  await tester.pumpAndSettle();
}

ScrollPosition _timeline(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(ChatTimeline),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position;

void main() {
  testWidgets('sending takes the reader to the end, wherever they were', (
    tester,
  ) async {
    final assistant = await _open(tester);
    await _send(tester, 'First question');
    await tester.drag(find.byType(ChatTimeline), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(_timeline(tester).extentAfter, greaterThan(300));

    await _send(tester, 'Second question');

    expect(_timeline(tester).extentAfter, lessThan(1));
    await tester.pumpWidget(const SizedBox());
    assistant.dispose();
  });

  testWidgets('a reader who scrolled back is not pulled to the end', (
    tester,
  ) async {
    final assistant = await _open(tester);
    await _send(tester, 'First question');
    await tester.drag(find.byType(ChatTimeline), const Offset(0, 400));
    await tester.pumpAndSettle();
    final reading = _timeline(tester).pixels;

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    expect(_timeline(tester).pixels, reading);
    await tester.pumpWidget(const SizedBox());
    assistant.dispose();
  });

  testWidgets('the keyboard does not hide the last message', (tester) async {
    final assistant = await _open(tester);
    await _send(tester, 'First question');
    expect(_timeline(tester).extentAfter, lessThan(1));

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    expect(_timeline(tester).extentAfter, lessThan(1));
    await tester.pumpWidget(const SizedBox());
    assistant.dispose();
  });
}
