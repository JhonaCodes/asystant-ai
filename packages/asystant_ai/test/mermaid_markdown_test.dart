import 'package:asystant_ai/asystant_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mermaid_flowchart_parser_test.dart' show keelPlan;

Widget host(Widget child) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

void main() {
  testWidgets('a mermaid fence in a message is drawn, not shown as code', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const AsystantMarkdownText(
          text: 'Plan for this session:\n\n```mermaid\n${keelPlan}```\n\nDone.',
        ),
      ),
    );
    expect(find.byType(AsystantMermaidDiagram), findsOneWidget);
    expect(find.textContaining('flowchart TD'), findsNothing);
    expect(find.bySemanticsLabel('Flowchart with 12 steps'), findsOneWidget);
    expect(find.text('Plan for this session:'), findsOneWidget);
    expect(find.text('Done.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('other fences, and Mermaid it cannot draw, stay code blocks', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const AsystantMarkdownText(
          text:
              '```dart\nvoid main() {}\n```\n\n'
              '```mermaid\nsequenceDiagram\n  Alice->>Bob: Hi\n```',
        ),
      ),
    );
    expect(find.byType(AsystantMermaidDiagram), findsNothing);
    expect(find.textContaining('void main() {}'), findsOneWidget);
    expect(find.textContaining('Alice->>Bob: Hi'), findsOneWidget);
  });

  testWidgets('a tap opens the full view; its action switches to the source', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const AsystantMarkdownText(
          text: '```mermaid\nflowchart LR\n  A[Pedido] -->|ok| B[Listo]\n```',
          strings: AsystantStrings.spanishLabels,
        ),
      ),
    );
    await tester.tap(find.byType(AsystantMermaidDiagram));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('Diagrama'), findsWidgets);

    await tester.tap(find.text('Ver código'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(
      find.textContaining('A[Pedido] -->|ok| B[Listo]', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.text('Ver diagrama'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('outside the chat: host link handler, selection and style', (
    tester,
  ) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      host(
        AsystantMarkdownText(
          text: '[Open task](https://example.test/tasks/7)',
          style: const TextStyle(fontSize: 21),
          selectable: true,
          onOpenLink: (uri) {
            opened.add(uri);
            return true;
          },
        ),
      ),
    );
    expect(find.byType(SelectionArea), findsOneWidget);
    final link = find.text('Open task', findRichText: true);
    // One line at 21 px with the paragraph's 1.5 line height.
    expect(tester.getSize(link).height, closeTo(21 * 1.5, .5));
    await tester.tap(link);
    await tester.pump();
    expect(opened.single.path, '/tasks/7');
  });
}
