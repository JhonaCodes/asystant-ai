import 'package:asystant_ai/asystant_ai.dart';
import 'package:asystant_ai/src/widgets/chat_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_flow_test.dart' show FakeTransport, WriteTool;

class _EmbeddedAssistant extends AsystantAI {
  _EmbeddedAssistant() : super(name: 'Workspace assistant');

  @override
  List<AsystantTool> get tools => [WriteTool()];
}

void main() {
  testWidgets('host field borders cannot create a nested composer outline', (
    tester,
  ) async {
    final assistant = _EmbeddedAssistant();
    assistant.init(transport: FakeTransport(), models: ['test']);
    await tester.runAsync(assistant.ensureInitialized);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(),
            disabledBorder: OutlineInputBorder(),
            errorBorder: OutlineInputBorder(),
            focusedErrorBorder: OutlineInputBorder(),
            filled: true,
          ),
        ),
        home: Scaffold(
          body: AsystantChat(
            assistant: assistant,
            strings: const AsystantStrings(spanish: false),
            onClose: () {},
          ),
        ),
      ),
    );
    final decoration = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!;
    expect(decoration.border, InputBorder.none);
    expect(decoration.enabledBorder, InputBorder.none);
    expect(decoration.focusedBorder, InputBorder.none);
    expect(decoration.disabledBorder, InputBorder.none);
    expect(decoration.errorBorder, InputBorder.none);
    expect(decoration.focusedErrorBorder, InputBorder.none);
    expect(decoration.filled, isFalse);
    expect(tester.getSize(find.byType(ChatHeader)).height, 72);
    final send = tester.getRect(find.byTooltip('Send'));
    final field = tester.getRect(find.byType(TextField));
    expect(send.center.dy, closeTo(field.center.dy, 4));
    expect(send.width, greaterThanOrEqualTo(48));
    expect(send.height, greaterThanOrEqualTo(48));

    await tester.enterText(find.byType(TextField), 'Create a branch draft');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(assistant.conversation.state.messages, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    assistant.dispose();
  });
}
