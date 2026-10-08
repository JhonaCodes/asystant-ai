import 'package:reactive_notifier/reactive_notifier.dart';

import 'package:asystant_ai/src/asystant_ai.dart';
import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/provider_settings_state.dart';
import 'package:asystant_ai/src/service/asystant_provider_settings.dart';

// keel-debt: loads data on ViewModel<T> with hand-made loading/availability
//   flags. AsyncViewModelImpl loads in its constructor before open() gives it
//   the assistant, and loadOnInit: false is banned here; migrate in a major,
//   with the opening as another notifier's state.
// keel-debt: stores already translated error text, so a host locale change
//   between openings shows the old language; store a failure enum and
//   translate it in the widget.
/// Loads, checks and applies the local chat provider of one assistant.
///
/// One instance per assistant, kept across openings of the settings sheet and
/// reset by [open]. It never holds the API key: [save], [verify] and
/// [removeKey] receive it as an argument and drop it when they return.
class ProviderSettingsViewModel extends ViewModel<ProviderSettingsState> {
  ProviderSettingsViewModel() : super(const ProviderSettingsState());

  /// Weak by key: an instance goes away with its assistant, never earlier.
  static final Expando<ProviderSettingsViewModel> _byAssistant = Expando(
    'ProviderSettingsViewModel',
  );

  /// The instance owned by [assistant], created on first use.
  static ProviderSettingsViewModel of(AsystantAI assistant) =>
      _byAssistant[assistant] ??= ProviderSettingsViewModel();

  AsystantAI? _assistant;
  AsystantStrings _strings = AsystantStrings.english;

  /// Bumped by [open]; work started by an earlier opening is discarded.
  int _opening = 0;

  AsystantProviderSettings? get _settings => _assistant?.providerSettings;

  List<String> get _hostModels =>
      _assistant?.conversation.notifier.state.models ?? const [];

  /// Loading needs an assistant, so it starts in [open], not here.
  @override
  void init() {}

  /// Starts a fresh opening for [assistant] and loads its saved selection.
  Future<void> open(AsystantAI assistant, AsystantStrings strings) async {
    final opening = ++_opening;
    _assistant = assistant;
    _strings = strings;
    updateState(const ProviderSettingsState());
    final settings = assistant.providerSettings;
    if (settings == null) {
      transformState(
        (state) => state.copyWith(
          isLoading: false,
          error: strings.providerSettingsUnavailable,
        ),
      );
      return;
    }
    transformState(
      (state) => state.copyWith(
        availableKinds: settings.availableKinds,
        isAvailable: true,
      ),
    );
    try {
      final selected = await settings.load();
      final hasKey = await settings.hasKey(selected.kind);
      final savedModels = await settings.modelsFor(selected.kind);
      _apply(
        opening,
        (state) => state.copyWith(
          kind: selected.kind,
          model: selected.model,
          baseUrl: selected.baseUrl,
          name: selected.name,
          hostModels: _hostModels,
          hasKey: hasKey,
          savedModels: savedModels,
          usesManagedOpenRouterCredential:
              selected.kind == .openRouter &&
              settings.usesManagedOpenRouterCredential,
          isLoading: false,
        ),
      );
    } on Object {
      _apply(
        opening,
        (state) => state.copyWith(
          hostModels: _hostModels,
          isLoading: false,
          error: strings.providerSecureStorageReadFailed,
        ),
      );
    }
  }

  /// Switches the provider; the saved model of the previous one no longer applies.
  Future<void> select(AsystantProviderKind kind) async {
    final settings = _settings;
    if (settings == null) return;
    final opening = _opening;
    transformState(
      (state) => state.copyWith(
        kind: kind,
        model: '',
        hostModels: _hostModels,
        hasKey: false,
        savedModels: const [],
        usesManagedOpenRouterCredential:
            kind == .openRouter && settings.usesManagedOpenRouterCredential,
        clearError: true,
        clearConnection: true,
      ),
    );
    final hasKey = await settings.hasKey(kind);
    final profile = await settings.profileFor(kind);
    final savedModels = await settings.modelsFor(kind);
    _apply(
      opening,
      (state) => state.kind == kind
          ? state.copyWith(
              hasKey: hasKey,
              model: profile.model,
              baseUrl: profile.baseUrl,
              name: profile.name,
              savedModels: savedModels,
            )
          : state,
    );
  }

  Future<void> addModel(String model) async {
    final settings = _settings;
    if (settings == null) return;
    final opening = _opening;
    final kind = data.kind;
    try {
      await settings.addModel(kind, model);
      final models = await settings.modelsFor(kind);
      _apply(
        opening,
        (state) => state.kind == kind
            ? state.copyWith(
                model: model.trim(),
                savedModels: models,
                clearError: true,
              )
            : state,
      );
    } on FormatException catch (error) {
      _apply(opening, (state) => state.copyWith(error: _formatError(error)));
    }
  }

  void selectSavedModel(String model) {
    if (data.savedModels.contains(model)) {
      transformState((state) => state.copyWith(model: model));
    }
  }

  Future<void> removeModel(String model) async {
    final settings = _settings;
    if (settings == null) return;
    final opening = _opening;
    final kind = data.kind;
    await settings.removeModel(kind, model);
    final models = await settings.modelsFor(kind);
    _apply(opening, (state) => state.kind == kind
        ? state.copyWith(savedModels: models)
        : state);
  }

  /// Stores the selection and [apiKey], then applies them to the chat.
  ///
  /// [onKeyStored] runs once the key is in secure storage, so the caller can
  /// drop its copy even if applying fails afterwards. Returns whether the new
  /// provider is in use.
  Future<bool> save({
    required String apiKey,
    required String model,
    required String baseUrl,
    required String name,
    required void Function() onKeyStored,
  }) async {
    final assistant = _assistant;
    final settings = _settings;
    if (assistant == null || settings == null || data.isSaving) return false;
    final opening = _opening;
    transformState((state) => state.copyWith(isSaving: true, clearError: true));
    try {
      await settings.save(
        _selection(model: model, baseUrl: baseUrl, name: name),
        apiKey: apiKey,
      );
      onKeyStored();
      await assistant.refreshProvider();
      return true;
    } on Object catch (error) {
      _apply(
        opening,
        (state) => state.copyWith(
          error: switch (error) {
            final FormatException rejected => _formatError(rejected),
            _ => _strings.providerApplyFailed,
          },
        ),
      );
      return false;
    } finally {
      _apply(opening, (state) => state.copyWith(isSaving: false));
    }
  }

  /// Checks the selection against the provider, preferring [keyOverride]
  /// over the stored key when it is not empty.
  Future<void> verify({
    required String keyOverride,
    required String model,
    required String baseUrl,
    required String name,
  }) async {
    final settings = _settings;
    if (settings == null || data.isSaving || data.usesHostProvider) return;
    final opening = _opening;
    transformState(
      (state) => state.copyWith(
        isSaving: true,
        clearError: true,
        clearConnection: true,
      ),
    );
    try {
      final provider = await settings.provider(
        _selection(model: model, baseUrl: baseUrl, name: name),
        keyOverride: keyOverride,
      );
      final verification = await provider.verify();
      _apply(
        opening,
        (state) => state.copyWith(
          connection: verification.when(
            ok: (_) => _strings.providerConnectionVerified,
            err: (_) => _strings.providerVerificationRejected,
          ),
        ),
      );
    } on FormatException catch (error) {
      _apply(opening, (state) => state.copyWith(error: _formatError(error)));
    } on Object {
      _apply(
        opening,
        (state) => state.copyWith(error: _strings.providerCheckFailed),
      );
    } finally {
      _apply(opening, (state) => state.copyWith(isSaving: false));
    }
  }

  /// Deletes the local key and goes back to the app account.
  ///
  /// [onKeyRemoved] runs once the key is gone from secure storage. Returns
  /// whether the app account is in use again.
  Future<bool> removeKey({required void Function() onKeyRemoved}) async {
    final assistant = _assistant;
    final settings = _settings;
    if (assistant == null ||
        settings == null ||
        data.isSaving ||
        data.usesHostProvider) {
      return false;
    }
    final opening = _opening;
    final kind = data.kind;
    transformState((state) => state.copyWith(isSaving: true));
    try {
      await settings.save(const AsystantProviderSelection());
      await settings.deleteKey(kind);
      onKeyRemoved();
      await assistant.refreshProvider();
      return true;
    } on Object {
      _apply(
        opening,
        (state) => state.copyWith(error: _strings.providerDeleteKeyFailed),
      );
      return false;
    } finally {
      _apply(opening, (state) => state.copyWith(isSaving: false));
    }
  }

  AsystantProviderSelection _selection({
    required String model,
    required String baseUrl,
    required String name,
  }) => AsystantProviderSelection(
    kind: data.kind,
    model: model.trim(),
    baseUrl: baseUrl.trim(),
    name: name.trim(),
  );

  String _formatError(FormatException error) =>
      _strings.providerFormatError(error.message);

  void _apply(
    int opening,
    ProviderSettingsState Function(ProviderSettingsState state) change,
  ) {
    if (opening == _opening) transformState(change);
  }
}
