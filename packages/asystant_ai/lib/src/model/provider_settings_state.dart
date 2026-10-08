import 'package:collection/collection.dart';

import 'package:asystant_ai/src/service/asystant_provider_settings.dart';

/// What the provider settings sheet shows; never serialized or persisted.
///
/// It deliberately has no field for the API key: the key travels only as a
/// method argument and must never outlive the call that uses it.
class ProviderSettingsState {
  const ProviderSettingsState({
    this.kind = AsystantProviderKind.backend,
    this.model = '',
    this.baseUrl = '',
    this.name = '',
    this.availableKinds = const [],
    this.hostModels = const [],
    this.savedModels = const [],
    this.usesManagedOpenRouterCredential = false,
    this.isLoading = true,
    this.isAvailable = false,
    this.isSaving = false,
    this.hasKey = false,
    this.error,
    this.connection,
  });

  final AsystantProviderKind kind;

  /// Saved model ID; seeds the model field when the form first appears.
  final String model;

  /// Saved base URL; seeds the base URL field when the form first appears.
  final String baseUrl;

  /// Saved provider name; seeds the name field when the form first appears.
  final String name;

  final List<AsystantProviderKind> availableKinds;

  /// Models the host provider allows, read when the selection loads.
  final List<String> hostModels;
  final List<String> savedModels;
  final bool usesManagedOpenRouterCredential;

  final bool isLoading;

  /// Whether the assistant was configured with provider settings at all.
  final bool isAvailable;

  /// Saving, verifying or deleting a key; every action is disabled meanwhile.
  final bool isSaving;

  /// Whether secure storage holds a key for [kind].
  final bool hasKey;

  final String? error;

  /// Result of the last connection check.
  final String? connection;

  bool get usesHostProvider => kind == .backend;

  /// A local key can be dropped only when the app account is a fallback.
  bool get canDeleteKey =>
      !usesHostProvider &&
      hasKey &&
      !usesManagedOpenRouterCredential &&
      availableKinds.contains(AsystantProviderKind.backend);

  ProviderSettingsState copyWith({
    AsystantProviderKind? kind,
    String? model,
    String? baseUrl,
    String? name,
    List<AsystantProviderKind>? availableKinds,
    List<String>? hostModels,
    List<String>? savedModels,
    bool? usesManagedOpenRouterCredential,
    bool? isLoading,
    bool? isAvailable,
    bool? isSaving,
    bool? hasKey,
    String? error,
    bool clearError = false,
    String? connection,
    bool clearConnection = false,
  }) => ProviderSettingsState(
    kind: kind ?? this.kind,
    model: model ?? this.model,
    baseUrl: baseUrl ?? this.baseUrl,
    name: name ?? this.name,
    availableKinds: List.unmodifiable(availableKinds ?? this.availableKinds),
    hostModels: List.unmodifiable(hostModels ?? this.hostModels),
    savedModels: List.unmodifiable(savedModels ?? this.savedModels),
    usesManagedOpenRouterCredential:
        usesManagedOpenRouterCredential ?? this.usesManagedOpenRouterCredential,
    isLoading: isLoading ?? this.isLoading,
    isAvailable: isAvailable ?? this.isAvailable,
    isSaving: isSaving ?? this.isSaving,
    hasKey: hasKey ?? this.hasKey,
    error: clearError ? null : error ?? this.error,
    connection: clearConnection ? null : connection ?? this.connection,
  );

  List<Object?> get _fields => [
    kind,
    model,
    baseUrl,
    name,
    availableKinds,
    hostModels,
    savedModels,
    usesManagedOpenRouterCredential,
    isLoading,
    isAvailable,
    isSaving,
    hasKey,
    error,
    connection,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderSettingsState &&
          const DeepCollectionEquality().equals(_fields, other._fields);

  @override
  int get hashCode => const DeepCollectionEquality().hash(_fields);
}
