import 'dart:async';
import 'dart:convert';

import 'package:asystant_ai/asystant_ai.dart';
import 'package:asystant_ai/src/model/provider_settings_state.dart';
import 'package:asystant_ai/src/viewmodel/provider_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const _hostModel = 'host-model';
const _secret = 'sk-never-in-state-7f3a';
const _selectionKey = 'asystant_ai.provider.acct.selection';
const _openAiKey = 'asystant_ai.provider.acct.key.openAi';

class _SettingsAssistant extends AsystantAI {
  _SettingsAssistant() : super(name: 'Settings');

  @override
  List<AsystantTool> get tools => const [];
}

/// Secure storage that can hold back the next read of the OpenAI key.
class _HeldStorage extends FlutterSecureStorage {
  _HeldStorage();

  final release = Completer<void>();
  bool _isHoldingNextRead = false;

  void holdNextKeyRead() => _isHoldingNextRead = true;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (_isHoldingNextRead && key == _openAiKey) {
      _isHoldingNextRead = false;
      await release.future;
    }
    return super.read(key: key);
  }
}

/// Secure storage whose platform side fails every read.
class _UnreadableStorage extends FlutterSecureStorage {
  const _UnreadableStorage();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => Future.error(PlatformException(code: 'read-failed'));
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

_SettingsAssistant _configuredAssistant({FlutterSecureStorage? storage}) =>
    _SettingsAssistant()..init(
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
      providerSettings: AsystantProviderSettings(
        namespace: 'acct',
        storage: storage,
      ),
    );

/// Every text the state carries, so no field can hide the key.
List<String> _texts(ProviderSettingsState state) => [
  state.model,
  state.baseUrl,
  state.name,
  ...state.hostModels,
  ?state.error,
  ?state.connection,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> storage;

  setUp(() {
    storage = {};
    FlutterSecureStorage.setMockInitialValues(storage);
  });

  test('open() discards what the previous opening left behind', () async {
    final assistant = _configuredAssistant();
    addTearDown(assistant.dispose);
    final viewModel = ProviderSettingsViewModel.of(assistant);

    await viewModel.open(assistant, AsystantStrings.english);
    final freshOpening = viewModel.data;
    await viewModel.select(.openAi);
    await viewModel.save(
      apiKey: 'sk-rejected',
      model: '',
      baseUrl: '',
      name: '',
      onKeyStored: () {},
    );
    expect(viewModel.data.kind, AsystantProviderKind.openAi);
    expect(viewModel.data.error, 'Enter a model ID.');

    final reopening = viewModel.open(assistant, AsystantStrings.english);
    expect(
      viewModel.data,
      ProviderSettingsState(
        availableKinds: assistant.providerSettings?.availableKinds ?? const [],
        isAvailable: true,
      ),
    );
    await reopening;

    expect(ProviderSettingsViewModel.of(assistant), same(viewModel));
    expect(viewModel.data, freshOpening);
    expect(viewModel.data.error, isNull);
  });

  test('the API key reaches secure storage but never the state', () async {
    final assistant = _configuredAssistant();
    addTearDown(assistant.dispose);
    final viewModel = ProviderSettingsViewModel.of(assistant);
    await viewModel.open(assistant, AsystantStrings.english);
    await viewModel.select(.openAi);

    final rejected = await viewModel.save(
      apiKey: _secret,
      model: '',
      baseUrl: '',
      name: '',
      onKeyStored: () {},
    );
    expect(rejected, isFalse);
    expect(_texts(viewModel.data), everyElement(isNot(contains(_secret))));

    var isKeyStored = false;
    final isApplied = await viewModel.save(
      apiKey: _secret,
      model: 'gpt-test',
      baseUrl: '',
      name: '',
      onKeyStored: () => isKeyStored = true,
    );

    expect(isApplied, isTrue);
    expect(isKeyStored, isTrue);
    expect(storage[_openAiKey], _secret);
    expect(_texts(viewModel.data), everyElement(isNot(contains(_secret))));
  });

  test(
    'a check started before reopening never lands on the new opening',
    () async {
      storage
        ..[_selectionKey] = jsonEncode({
          'kind': 'openAi',
          'model': 'gpt-saved',
          'baseUrl': '',
          'name': '',
        })
        ..[_openAiKey] = 'sk-saved';
      final heldStorage = _HeldStorage();
      final assistant = _configuredAssistant(storage: heldStorage);
      addTearDown(assistant.dispose);
      final viewModel = ProviderSettingsViewModel.of(assistant);
      await viewModel.open(assistant, AsystantStrings.english);

      heldStorage.holdNextKeyRead();
      final staleCheck = viewModel.verify(
        keyOverride: '',
        model: 'gpt-saved',
        baseUrl: '',
        name: '',
      );
      expect(viewModel.data.isSaving, isTrue);

      await viewModel.open(assistant, AsystantStrings.english);
      final reopened = viewModel.data;
      heldStorage.release.complete();
      await staleCheck;

      expect(reopened.isSaving, isFalse);
      expect(viewModel.data.connection, isNull);
      expect(viewModel.data, reopened);
    },
  );

  testWidgets(
    'a secure storage read failure keeps the form and reports it inline',
    (tester) async {
      final assistant = _configuredAssistant(
        storage: const _UnreadableStorage(),
      );
      addTearDown(assistant.dispose);

      await tester.pumpWidget(
        MaterialApp(home: _SheetLauncher(assistant: assistant)),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Chat provider'), findsOneWidget);
      expect(find.text('Save and use'), findsOneWidget);
      expect(find.text('Could not read secure storage.'), findsOneWidget);
      expect(find.text('Settings are unavailable.'), findsNothing);
    },
  );
}
