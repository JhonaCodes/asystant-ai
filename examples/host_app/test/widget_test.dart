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
    await assistant.init(transport: DemoTransport());
    await tester.pumpWidget(HostApp(assistant: assistant));
    await tester.tap(find.text('Asistente').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Preparar una clase');
    await tester.pump();
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Continuar'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Borrador guardado'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('Preparar una clase'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    assistant.dispose();
  });
}
