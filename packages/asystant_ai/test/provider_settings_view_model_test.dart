import 'package:asystant_ai/asystant_ai.dart';
import 'package:asystant_ai/src/model/provider_settings_state.dart';
import 'package:asystant_ai/src/viewmodel/provider_settings_view_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const _hostModel = 'host-model';
const _secret = 'sk-never-in-state-7f3a';

class _SettingsAssistant extends AsystantAI {
  _SettingsAssistant() : super(name: 'Settings');

  @override
  List<AsystantTool> get tools => const [];
}

_SettingsAssistant _configuredAssistant() => _SettingsAssistant()
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
    providerSettings: AsystantProviderSettings(namespace: 'acct'),
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
    expect(storage['asystant_ai.provider.acct.key.openAi'], _secret);
    expect(_texts(viewModel.data), everyElement(isNot(contains(_secret))));
  });
}
