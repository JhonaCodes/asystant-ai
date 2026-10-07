// Characterization oracle for the provider settings sheet (plan §5.4, WP-7).
// Drives only public API; fakes only the secure storage platform boundary.
import 'dart:convert';

import 'package:asystant_ai/asystant_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const _namespace = 'acct';
const _selectionKey = 'asystant_ai.provider.$_namespace.selection';
const _openAiKey = 'asystant_ai.provider.$_namespace.key.openAi';
const _openRouterKey = 'asystant_ai.provider.$_namespace.key.openRouter';
const _hostModel = 'host-model';

class _SettingsAssistant extends AsystantAI {
  _SettingsAssistant() : super(name: 'Settings');

  @override
  List<AsystantTool> get tools => const [];
}

class _SheetLauncher extends StatelessWidget {
  const _SheetLauncher({required this.assistant});

  final AsystantAI assistant;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () =>
            showAsystantProviderSettings(context, assistant: assistant),
        child: const Text('Open'),
      ),
    ),
  );
}

/// An assistant whose host provider and local settings never touch the network.
_SettingsAssistant _configuredAssistant() {
  final assistant = _SettingsAssistant()
    ..init(
      provider: OpenAICompatibleProvider(
        credentials: () async => Ok(
          const OpenRouterCredential(
            apiKey: 'host-key',
            allowedModels: [_hostModel],
          ),
        ),
        baseUri: Uri.parse('https://host.example/v1/'),
        providerName: 'Host',
        model: _hostModel,
      ),
      models: [AsystantModelOption.fallback(_hostModel)],
      providerSettings: AsystantProviderSettings(namespace: _namespace),
    );
  return assistant;
}

Future<void> _openSheet(WidgetTester tester, AsystantAI assistant) async {
  await tester.pumpWidget(
    MaterialApp(home: _SheetLauncher(assistant: assistant)),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> _chooseKind(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButtonFormField<AsystantProviderKind>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Map<String, Object?> _savedSelection(Map<String, String> storage) =>
    jsonDecode(storage[_selectionKey]!) as Map<String, Object?>;

void main() {
  late Map<String, String> storage;

  setUp(() {
    storage = {};
    FlutterSecureStorage.setMockInitialValues(storage);
  });

  testWidgets('opening loads the saved selection and shows its kind', (
    tester,
  ) async {
    storage
      ..[_selectionKey] = jsonEncode({
        'kind': 'openRouter',
        'model': 'openai/gpt-saved',
        'baseUrl': '',
        'name': '',
      })
      ..[_openRouterKey] = 'sk-saved';
    final assistant = _configuredAssistant();
    addTearDown(assistant.dispose);

    await _openSheet(tester, assistant);

    expect(find.text('Chat provider'), findsOneWidget);
    expect(find.text('OpenRouter'), findsOneWidget);
    expect(find.text('App account'), findsNothing);
    expect(find.text('openai/gpt-saved'), findsOneWidget);
    expect(find.text('Key saved. Leave blank to keep it.'), findsOneWidget);
  });

  testWidgets(
    'choosing a kind, entering a key and saving stores both and closes',
    (tester) async {
      final assistant = _configuredAssistant();
      addTearDown(assistant.dispose);

      await _openSheet(tester, assistant);
      expect(find.text('App account'), findsOneWidget);

      await _chooseKind(tester, 'OpenAI / GPT');
      await tester.enterText(
        find.widgetWithText(TextField, 'Primary model ID'),
        'gpt-test',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'API key'),
        'sk-test',
      );
      await tester.tap(find.text('Save and use'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(storage[_openAiKey], 'sk-test');
      expect(_savedSelection(storage), {
        'kind': 'openAi',
        'model': 'gpt-test',
        'baseUrl': '',
        'name': '',
      });
      expect(find.text('Chat provider'), findsNothing);
      // refreshProvider reconfigured the chat with the newly saved model.
      final chat = assistant.conversation.notifier.state;
      expect(chat.phase, ChatPhase.ready);
      expect(chat.models, ['gpt-test']);
    },
  );

  testWidgets(
    'deleting the local key removes it and falls back to the app account',
    (tester) async {
      storage
        ..[_selectionKey] = jsonEncode({
          'kind': 'openAi',
          'model': 'gpt-saved',
          'baseUrl': '',
          'name': '',
        })
        ..[_openAiKey] = 'sk-saved';
      final assistant = _configuredAssistant();
      addTearDown(assistant.dispose);

      await _openSheet(tester, assistant);
      await tester.tap(find.text('Delete local key'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(storage.containsKey(_openAiKey), isFalse);
      expect(_savedSelection(storage)['kind'], 'backend');
      expect(find.text('Chat provider'), findsNothing);
      // refreshProvider went back to the host provider and its models.
      final chat = assistant.conversation.notifier.state;
      expect(chat.phase, ChatPhase.ready);
      expect(chat.models, [_hostModel]);
    },
  );

  testWidgets(
    'a rejected save keeps the sheet open, shows the error, writes nothing',
    (tester) async {
      final assistant = _configuredAssistant();
      addTearDown(assistant.dispose);

      await _openSheet(tester, assistant);
      await _chooseKind(tester, 'OpenAI / GPT');
      // No model ID: validation rejects the selection before any write.
      await tester.enterText(
        find.widgetWithText(TextField, 'API key'),
        'sk-rejected',
      );
      await tester.tap(find.text('Save and use'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Chat provider'), findsOneWidget);
      expect(find.text('Enter a model ID.'), findsOneWidget);
      expect(storage, isEmpty);
      expect(assistant.conversation.notifier.state.phase, ChatPhase.idle);
    },
  );
}
