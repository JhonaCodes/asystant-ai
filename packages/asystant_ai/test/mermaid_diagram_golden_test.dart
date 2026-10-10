import 'dart:io';

import 'package:asystant_ai/asystant_ai.dart';
import 'package:asystant_ai/src/widgets/asystant_link_scope.dart';
import 'package:asystant_ai/src/widgets/chat_message_bubble.dart';
import 'package:asystant_ai/src/widgets/mermaid_diagram_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mermaid_flowchart_parser_test.dart' show keelPlan;

const connectedPlan = '''
flowchart TD
  A[Inventario con file:line y mapeo de tipos] --> B[Cargo.toml: feature sqlite + returning]
  B --> C[5 migraciones a dialecto SQLite]
  C --> D{Compila el schema?}
  D -->|No| C
  D -->|Si| E[Pool con PRAGMA foreign_keys]
  E --> F{PRAGMA foreign_keys activo?}
  F -->|No| G[ON DELETE CASCADE roto en silencio] --> E
  F -->|Si| H[WAL una vez antes del pool]
  H --> I[readyz con query Diesel count_star]
  I --> J([Entregar sin commitear para auditoria])
''';

Widget chat(String source, {required Brightness brightness}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: brightness,
    ),
  ),
  // AsystantChat provides its strings and link handling this way.
  home: AsystantLinkScope(
    opener: const AsystantLinkOpener(),
    strings: AsystantStrings.spanishLabels,
    child: Scaffold(
      body: AsystantMetricsScope(
        metrics: AsystantMetrics.compact,
        child: ListView(
          padding: AsystantMetrics.compact.listPadding,
          children: [
            ChatMessageBubble(
              text:
                  'Plan de la sesión:\n\n```mermaid\n$source```\n\n'
                  'Lo entrego sin commitear.',
              fromUser: false,
              author: 'Keel',
              strings: AsystantStrings.spanishLabels,
            ),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Flutter test runs from either the workspace or package directory.
    final font = File('test/fonts/Roboto-Regular.ttf').existsSync()
        ? File('test/fonts/Roboto-Regular.ttf')
        : File('packages/asystant_ai/test/fonts/Roboto-Regular.ttf');
    final loader = FontLoader('Roboto')
      ..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())));
    await loader.load();
  });

  final diagram = find.byWidgetPredicate(
    (widget) =>
        widget is CustomPaint && widget.painter is MermaidDiagramPainter,
  );

  Future<void> sized(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('the keel plan in a 390 px chat, then in the full view', (
    tester,
  ) async {
    await sized(tester, const Size(390, 520));
    await tester.pumpWidget(chat(keelPlan, brightness: Brightness.light));
    expect(diagram, findsOneWidget);
    expect(find.textContaining('flowchart'), findsNothing);
    expect(tester.takeException(), isNull);
    // Golden baselines are recorded on macOS, like the other chat goldens.
    if (Platform.isMacOS) {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/mermaid_chat_390.png'),
      );
    }
    await sized(tester, const Size(390, 760));
    await tester.tap(find.byType(AsystantMermaidDiagram));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('Ver código'), findsOneWidget);
    if (Platform.isMacOS) {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/mermaid_viewer_390.png'),
      );
    }
  });

  testWidgets('a connected plan with back edges, dark theme', (tester) async {
    await sized(tester, const Size(390, 640));
    await tester.pumpWidget(chat(connectedPlan, brightness: Brightness.dark));
    expect(diagram, findsOneWidget);
    expect(tester.takeException(), isNull);
    if (Platform.isMacOS) {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/mermaid_chat_dark_390.png'),
      );
    }
  });
}
