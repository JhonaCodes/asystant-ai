import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_app/host_app.dart';
import 'package:host_app/demo_transport.dart';
import 'package:host_app/workspace_assistant.dart';

void main() {
  testWidgets('embedded chat opens from the host button and preserves draft', (
    tester,
  ) async {
    final assistant = WorkspaceAssistant();
    assistant.init(transport: DemoTransport());
    await tester.runAsync(assistant.ensureInitialized);
    await tester.pumpWidget(HostApp(assistant: assistant));
    await tester.tap(find.text('Assistant').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Prepare a lesson');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Draft saved'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Prepare a lesson'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    assistant.dispose();
  });
}
