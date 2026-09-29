import 'package:asystant_ai/asystant_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_flow_test.dart' show FakeTransport;

class _PhoneAssistant extends AsystantAI {
  _PhoneAssistant() : super(name: 'Botánica');

  @override
  List<AsystantTool> get tools => const [];
}

void main() {
  for (final (startsExpanded, staysOpen) in [(true, true), (false, false)]) {
    testWidgets(
      'dragging the header down ${staysOpen ? 'keeps the whole-screen chat' : 'closes the sheet'}',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final assistant = _PhoneAssistant()
          ..init(
            transport: FakeTransport(),
            models: [AsystantModelOption.fallback('test')],
          );
        await tester.runAsync(assistant.ensureInitialized);
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => AsystantPhoneSheet.show(
                      context,
                      assistant: assistant,
                      startsExpanded: startsExpanded,
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.drag(find.text('Botánica'), const Offset(0, 500));
        await tester.pumpAndSettle();

        expect(
          find.byType(AsystantChat),
          staysOpen ? findsOneWidget : findsNothing,
        );
        await tester.pumpWidget(const SizedBox());
        assistant.dispose();
      },
    );
  }
}
