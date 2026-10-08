import 'package:asystant_ai/asystant_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _Assistant extends AsystantAI {
  @override
  List<AsystantTool> get tools => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'managed OpenRouter uses the host credential and its allowlist',
    () async {
      final settings = AsystantProviderSettings(
        namespace: 'managed',
        managedOpenRouterCredentials: () async => Ok(
          const OpenRouterCredential(
            apiKey: 'managed-key',
            allowedModels: ['sample/allowed'],
          ),
        ),
        openRouterAppName: 'Keel',
        openRouterAppUrl: 'https://api.jhonacode.com/v1/keel-bot',
      );
      expect(await settings.hasKey(.openRouter), isTrue);
      expect(
        (await settings.openRouterCredential())?.authorization,
        'Bearer managed-key',
      );
      await settings.save(
        const AsystantProviderSelection(
          kind: .openRouter,
          model: 'sample/allowed',
        ),
      );
      expect((await settings.load()).model, 'sample/allowed');
      expect(
        () => settings.save(
          const AsystantProviderSelection(
            kind: .openRouter,
            model: 'sample/blocked',
          ),
        ),
        throwsFormatException,
      );
      final provider = await settings.provider(
        const AsystantProviderSelection(
          kind: .openRouter,
          model: 'sample/allowed',
        ),
      ) as OpenRouterProvider;
      expect(provider.appName, 'Keel');
      expect(provider.appUrl, 'https://api.jhonacode.com/v1/keel-bot');
    },
  );

  testWidgets('managed OpenRouter does not show an API key field', (
    tester,
  ) async {
    final settings = AsystantProviderSettings(
      namespace: 'managed-ui',
      availableKinds: const [.backend, .openRouter],
      managedOpenRouterCredentials: () async => Ok(
        const OpenRouterCredential(
          apiKey: 'managed-key',
          allowedModels: ['sample/allowed'],
        ),
      ),
    );
    final assistant = _Assistant();
    assistant.init(
      provider: OpenRouterProvider(
        credentials: settings.managedOpenRouterCredentials!,
      ),
      providerSettings: settings,
    );
    addTearDown(assistant.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAsystantProviderSettings(
                context,
                assistant: assistant,
                strings: const AsystantStrings(spanish: true),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byType(DropdownButtonFormField<AsystantProviderKind>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OpenRouter').last);
    await tester.pumpAndSettle();
    expect(find.text('Clave API'), findsNothing);
    expect(find.textContaining('clave de la cuenta'), findsOneWidget);
  });
}
