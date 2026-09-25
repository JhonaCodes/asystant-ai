import 'package:asystant_ai/asystant_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_flow_test.dart' show FakeTransport, WriteTool, settle;

class TestAssistant extends AsystantAI {
  TestAssistant() : super(name: 'Ayuda de mi app');
  @override
  List<AsystantTool> get tools => [WriteTool()];
}

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(600, 320),
    const Size(1440, 900),
  ]) {
    testWidgets('embedded section works at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final assistant = TestAssistant();
      assistant.init(transport: FakeTransport(), models: ['test']);
      await tester.runAsync(assistant.ensureInitialized);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsystantChat(
              assistant: assistant,
              strings: const AsystantStrings(),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Ayuda de mi app'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Create a draft');
      await tester.pump();
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();
      expect(find.text('Continuar'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Ahora no'));
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      assistant.dispose();
    });
  }
  testWidgets('mobile keyboard and larger text keep send accessible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final assistant = TestAssistant();
    assistant.init(transport: FakeTransport(), models: ['test']);
    await tester.runAsync(assistant.ensureInitialized);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(1.5),
            viewInsets: EdgeInsets.only(bottom: 280),
          ),
          child: Scaffold(
            body: AsystantChat(
              assistant: assistant,
              strings: const AsystantStrings(),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'A draft');
    await tester.pump();
    expect(find.text('Enviar').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    assistant.dispose();
  });
  test('instances never share drafts or permission state', () async {
    final a = TestAssistant(), b = TestAssistant();
    a.init(transport: FakeTransport(), models: ['test']);
    await a.ensureInitialized();
    b.init(transport: FakeTransport(), models: ['test']);
    await b.ensureInitialized();
    a.conversation.notifier.setDraft('only a');
    final turn = a.conversation.notifier.send();
    await settle();
    expect(a.conversation.state.phase, ChatPhase.permission);
    expect(b.conversation.state.messages, isEmpty);
    expect(b.conversation.state.draft, isEmpty);
    a.conversation.notifier.approve(false);
    await turn;
    a.dispose();
    b.dispose();
  });
}
