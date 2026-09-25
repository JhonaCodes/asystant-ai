import 'dart:io';

import 'package:asystant_ai/asystant_ai.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_flow_test.dart' show FakeTransport, WriteTool;

class _PreviewAssistant extends AsystantAI {
  _PreviewAssistant() : super(name: 'Workspace assistant');

  @override
  List<AsystantTool> get tools => [WriteTool()];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Deliberately load no MaterialIcons: essential controls use bundled vectors.
    final font = File('test/fonts/Roboto-Regular.ttf').existsSync()
        ? File('test/fonts/Roboto-Regular.ttf')
        : File('packages/asystant_ai/test/fonts/Roboto-Regular.ttf');
    final loader = FontLoader('Roboto')
      ..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())));
    await loader.load();
  });

  for (final width in [390.0, 900.0]) {
    testWidgets('chat controls remain visible without icon fonts at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final assistant = _PreviewAssistant();
      assistant.init(
        transport: FakeTransport(),
        models: ['openai/gpt-oss-120b'],
      );
      await tester.runAsync(assistant.ensureInitialized);
      var closed = false;
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff10b981),
            ),
          ),
          home: Scaffold(
            body: Align(
              alignment: .centerRight,
              child: SizedBox(
                width: 460,
                child: AsystantChat(
                  assistant: assistant,
                  strings: const AsystantStrings(spanish: false),
                  onClose: () => closed = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Close').hitTestable(), findsOneWidget);
      expect(find.byTooltip('Send').hitTestable(), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is AsystantGlyph && widget.kind == AsystantGlyphKind.close,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      if (Platform.isMacOS) {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/chat_${width.toInt()}.png'),
        );
      }
      await tester.enterText(
        find.byType(TextField),
        'Create a draft for the new branch.',
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(find.text('Continue').hitTestable(), findsOneWidget);
      if (Platform.isMacOS) {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/chat_permission_${width.toInt()}.png'),
        );
      }
      await tester.tap(find.byTooltip('Close'));
      expect(closed, isTrue);
      await tester.pumpWidget(const SizedBox());
      assistant.dispose();
    });
  }
}
