import 'dart:convert';

import 'package:asystant_core/asystant_core.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The local source used for the main chat. `backend` keeps the host provider.
enum AsystantProviderKind {
  backend,
  openAi,
  openRouter,
  gemini,
  anthropic,
  compatible,
}

/// Non-secret settings; the API key is held in secure storage separately.
class AsystantProviderSelection {
  const AsystantProviderSelection({
    this.kind = AsystantProviderKind.backend,
    this.model = '',
    this.baseUrl = '',
    this.name = '',
  });

  final AsystantProviderKind kind;
  final String model;
  final String baseUrl;
  final String name;

  String get label => switch (kind) {
    .backend => 'Backend',
    .openAi => 'OpenAI',
    .openRouter => 'OpenRouter',
    .gemini => 'Gemini',
    .anthropic => 'Claude API',
    .compatible => name.trim().isEmpty ? 'OpenAI-compatible' : name.trim(),
  };

  Uri get endpoint => switch (kind) {
    .openRouter => Uri.parse('https://openrouter.ai/api/v1/'),
    .openAi => Uri.parse('https://api.openai.com/v1/'),
    .gemini => Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/openai/',
    ),
    .anthropic => Uri.parse('https://api.anthropic.com/v1/'),
    .compatible => Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'),
    .backend => throw StateError('The backend uses the host provider.'),
  };

  void validate() {
    if (kind == .backend) return;
    if (model.trim().isEmpty) throw const FormatException('Enter a model ID.');
    final uri = endpoint;
    if (uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException('Enter an HTTPS API base URL.');
    }
  }

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'model': model,
    'baseUrl': baseUrl,
    'name': name,
  };

  factory AsystantProviderSelection.fromJson(Map<String, Object?> value) =>
      AsystantProviderSelection(
        kind: AsystantProviderKind.values.firstWhere(
          (kind) => kind.name == value['kind'],
          orElse: () => .backend,
        ),
        model: value['model'] as String? ?? '',
        baseUrl: value['baseUrl'] as String? ?? '',
        name: value['name'] as String? ?? '',
      );
}

/// Optional, library-owned provider configuration for one host account.
/// The host supplies a stable, account-specific [namespace]. Never pass keys
/// through messages, analytics, previews or conversation storage.
class AsystantProviderSettings {
  AsystantProviderSettings({
    required this.namespace,
    FlutterSecureStorage? storage,
    this.managedOpenRouterCredentials,
    this.openRouterAppName,
    this.openRouterAppUrl,
    this.showInChatMenu = true,
    List<AsystantProviderKind> availableKinds = const [
      AsystantProviderKind.backend,
      AsystantProviderKind.openAi,
      AsystantProviderKind.openRouter,
      AsystantProviderKind.gemini,
      AsystantProviderKind.anthropic,
      AsystantProviderKind.compatible,
    ],
  }) : availableKinds = List.unmodifiable(availableKinds),
       _storage = storage ?? const FlutterSecureStorage() {
    if (availableKinds.isEmpty ||
        availableKinds.toSet().length != availableKinds.length) {
      throw ArgumentError.value(
        availableKinds,
        'availableKinds',
        'Provide unique provider kinds.',
      );
    }
  }

  final String namespace;
  final FlutterSecureStorage _storage;
  final OpenRouterCredentialSource? managedOpenRouterCredentials;
  final String? openRouterAppName;
  final String? openRouterAppUrl;
  bool get usesManagedOpenRouterCredential =>
      managedOpenRouterCredentials != null;

  /// A managed app can hide provider settings while continuing to use its
  /// backend credential. The host can also omit this settings object entirely.
  final bool showInChatMenu;

  /// Only these sources appear in settings and may be selected. Removing a
  /// previously selected source makes [load] use the first available source.
  final List<AsystantProviderKind> availableKinds;

  String get _prefix => 'asystant_ai.provider.$namespace';
  String get _selectionKey => '$_prefix.selection';
  String _secretKey(AsystantProviderKind kind) => '$_prefix.key.${kind.name}';
  String _profileKey(AsystantProviderKind kind) =>
      '$_prefix.profile.${kind.name}';
  String _modelsKey(AsystantProviderKind kind) =>
      '$_prefix.models.${kind.name}';

  /// Restores a provider's last endpoint and model after switching away.
  Future<AsystantProviderSelection> profileFor(
    AsystantProviderKind kind,
  ) async {
    final raw = await _storage.read(key: _profileKey(kind));
    if (raw == null) {
      final active = await load();
      return active.kind == kind
          ? active
          : AsystantProviderSelection(kind: kind);
    }
    try {
      final profile = AsystantProviderSelection.fromJson(
        jsonDecode(raw) as Map<String, Object?>,
      );
      return profile.kind == kind
          ? profile
          : AsystantProviderSelection(kind: kind);
    } on Object {
      return AsystantProviderSelection(kind: kind);
    }
  }

  /// Models explicitly saved for one personal provider on this device.
  Future<List<String>> modelsFor(AsystantProviderKind kind) async {
    if (kind == .backend) return const [];
    final raw = await _storage.read(key: _modelsKey(kind));
    if (raw != null) {
      try {
        final values = jsonDecode(raw) as List<Object?>;
        return List.unmodifiable(
          values
              .whereType<String>()
              .where((id) => id.trim().isNotEmpty)
              .toSet(),
        );
      } on Object {
        // Fall through to the saved active profile.
      }
    }
    final selected = await profileFor(kind);
    return selected.model.trim().isEmpty ? const [] : [selected.model.trim()];
  }

  Future<void> addModel(AsystantProviderKind kind, String model) async {
    if (kind == .backend || !availableKinds.contains(kind)) {
      throw const FormatException('Choose a personal provider.');
    }
    final id = model.trim();
    if (id.isEmpty) throw const FormatException('Enter a model ID.');
    if (kind == .openRouter && usesManagedOpenRouterCredential) {
      await _validateManagedModel(id);
    }
    await _storeModel(kind, id);
  }

  Future<void> _storeModel(AsystantProviderKind kind, String id) async {
    final models = {...await modelsFor(kind), id}.toList(growable: false);
    await _storage.write(key: _modelsKey(kind), value: jsonEncode(models));
  }

  Future<void> removeModel(AsystantProviderKind kind, String model) async {
    final models = (await modelsFor(kind))
        .where((id) => id != model)
        .toList(growable: false);
    await _storage.write(key: _modelsKey(kind), value: jsonEncode(models));
  }

  Future<AsystantProviderSelection> load() async {
    final raw = await _storage.read(key: _selectionKey);
    if (raw == null) {
      return AsystantProviderSelection(kind: availableKinds.first);
    }
    try {
      final selected = AsystantProviderSelection.fromJson(
        jsonDecode(raw) as Map<String, Object?>,
      );
      return availableKinds.contains(selected.kind)
          ? selected
          : AsystantProviderSelection(kind: availableKinds.first);
    } on Object {
      return AsystantProviderSelection(kind: availableKinds.first);
    }
  }

  Future<bool> hasKey(AsystantProviderKind kind) async =>
      kind == .openRouter && usesManagedOpenRouterCredential
      ? true
      : (await _storage.read(key: _secretKey(kind)))?.isNotEmpty ?? false;

  /// The host may use the saved OpenRouter key for account quota checks and
  /// free-model routing. The credential never enters chat or preferences.
  Future<OpenRouterCredential?> openRouterCredential() async {
    if (managedOpenRouterCredentials case final source?) {
      final result = await source();
      return result.when(ok: (credential) => credential, err: (_) => null);
    }
    final key = await _storage.read(key: _secretKey(.openRouter));
    return key == null || key.isEmpty
        ? null
        : OpenRouterCredential(apiKey: key);
  }

  /// Replaces a key only when [apiKey] is supplied. Empty input retains it.
  Future<void> save(
    AsystantProviderSelection selection, {
    String? apiKey,
  }) async {
    selection.validate();
    if (!availableKinds.contains(selection.kind)) {
      throw const FormatException(
        'This provider is not available in this app.',
      );
    }
    if (selection.kind == .openRouter && usesManagedOpenRouterCredential) {
      await _validateManagedModel(selection.model);
    }
    if (selection.kind != .backend &&
        (apiKey == null || apiKey.trim().isEmpty) &&
        !await hasKey(selection.kind)) {
      throw const FormatException('Enter an API key.');
    }
    if (selection.kind != .backend &&
        !(selection.kind == .openRouter && usesManagedOpenRouterCredential) &&
        apiKey != null &&
        apiKey.trim().isNotEmpty) {
      await _storage.write(
        key: _secretKey(selection.kind),
        value: apiKey.trim(),
      );
    }
    await _storage.write(
      key: _selectionKey,
      value: jsonEncode(selection.toJson()),
    );
    await _storage.write(
      key: _profileKey(selection.kind),
      value: jsonEncode(selection.toJson()),
    );
    if (selection.kind != .backend) {
      await _storeModel(selection.kind, selection.model.trim());
    }
  }

  Future<void> deleteKey(AsystantProviderKind kind) =>
      _storage.delete(key: _secretKey(kind));

  Future<void> _validateManagedModel(String model) async {
    final credential = await openRouterCredential();
    if (credential == null) {
      throw const FormatException(
        'Could not obtain the app account credential.',
      );
    }
    if (!credential.allowedModels.contains(model.trim())) {
      throw const FormatException(
        'This model is not enabled for the app account.',
      );
    }
  }

  Future<AsystantProvider> provider(
    AsystantProviderSelection selection, {
    String? keyOverride,
  }) async {
    selection.validate();
    if (!availableKinds.contains(selection.kind)) {
      throw StateError('This provider is not available in this app.');
    }
    if (selection.kind == .backend) throw StateError('Use the host provider.');
    if (selection.kind == .openRouter && usesManagedOpenRouterCredential) {
      await _validateManagedModel(selection.model);
      return OpenRouterProvider(
        credentials: managedOpenRouterCredentials!,
        identity: () => 'managed:$namespace',
        appName: openRouterAppName,
        appUrl: openRouterAppUrl,
      );
    }
    if ((keyOverride == null || keyOverride.trim().isEmpty) &&
        !await hasKey(selection.kind)) {
      throw StateError('No API key is saved for ${selection.label}.');
    }
    Future<Result<OpenRouterCredential, AssistantFailure>> credentials() async {
      final key = keyOverride != null && keyOverride.trim().isNotEmpty
          ? keyOverride.trim()
          : await _storage.read(key: _secretKey(selection.kind));
      if (key == null || key.isEmpty) {
        return Err(const AssistantFailure(.authentication));
      }
      return Ok(
        OpenRouterCredential(
          apiKey: key,
          allowedModels: [selection.model.trim()],
        ),
      );
    }

    final endpointId = sha256.convert(
      utf8.encode(selection.endpoint.toString()),
    );
    String identity() => 'local:$namespace:${selection.kind.name}:$endpointId';
    if (selection.kind == .openRouter) {
      return OpenRouterProvider(
        credentials: credentials,
        identity: identity,
        appName: openRouterAppName,
        appUrl: openRouterAppUrl,
      );
    }
    return OpenAICompatibleProvider(
      providerName: selection.label,
      baseUri: selection.endpoint,
      model: selection.model.trim(),
      identity: identity,
      credentials: credentials,
    );
  }
}
