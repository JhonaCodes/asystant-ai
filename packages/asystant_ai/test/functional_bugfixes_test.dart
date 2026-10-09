// Covers V8 (null providerSettings crash) and V9 (TOTP completeness drift).
import 'package:asystant_ai/asystant_ai.dart';
import 'package:asystant_ai/src/widgets/chat_private_input_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_flow_test.dart' show FakeTransport;

class _BugfixAssistant extends AsystantAI {
  _BugfixAssistant() : super(name: 'Bugfix');

  @override
  List<AsystantTool> get tools => const [];
}

void main() {
  testWidgets(
    'opening provider settings with no providerSettings configured renders '
    'an error state instead of crashing',
    (tester) async {
      final assistant = _BugfixAssistant()
        ..init(
          transport: FakeTransport(),
          models: [AsystantModelOption.fallback('test')],
        );
      addTearDown(assistant.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showAsystantProviderSettings(
                    context,
                    assistant: assistant,
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

      expect(tester.takeException(), isNull);
      expect(find.text('Settings are unavailable.'), findsOneWidget);
    },
  );

  group('private input completeness (V9)', () {
    const request = PrivateInputRequest(
      id: 'req-1',
      title: 'Confirm',
      fields: [
        PrivateInputField(name: 'password', label: 'Password'),
        PrivateInputField(name: 'otp', label: 'Code', kind: .totp),
      ],
    );

    Future<void> pumpCard(
      WidgetTester tester, {
      required ValueChanged<Map<String, String>> onSubmit,
    }) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatPrivateInputCard(
            request: request,
            strings: const AsystantStrings(),
            onSubmit: onSubmit,
            onCancel: () {},
          ),
        ),
      ),
    );

    testWidgets(
      'submit stays disabled until the TOTP field also matches its pattern',
      (tester) async {
        var submitted = false;
        await pumpCard(tester, onSubmit: (_) => submitted = true);

        await tester.enterText(find.byType(TextField).first, 'secret');
        await tester.pump();

        // Both fields non-empty but the TOTP value is too short: the
        // non-TOTP-aware check used to enable this button anyway.
        await tester.enterText(find.byType(TextField).last, '12');
        await tester.pump();

        final submitButton = tester.widget<FilledButton>(
          find.byType(FilledButton),
        );
        expect(submitButton.onPressed, isNull);

        await tester.tap(find.byType(FilledButton));
        await tester.pump();
        expect(submitted, isFalse);

        await tester.enterText(find.byType(TextField).last, '123456');
        await tester.pump();

        final enabledButton = tester.widget<FilledButton>(
          find.byType(FilledButton),
        );
        expect(enabledButton.onPressed, isNotNull);

        await tester.tap(find.byType(FilledButton));
        await tester.pump();
        expect(submitted, isTrue);
      },
    );
  });
}
