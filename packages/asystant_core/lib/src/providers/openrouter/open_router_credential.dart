import 'package:collection/collection.dart';
import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/model/assistant_failure.dart';

/// Obtains the OpenRouter key of the signed-in user.
///
/// In production the host backend asks asystant-api for it
/// (`POST /v1/managed/credentials`) and returns the response to the app; see
/// [OpenRouterCredential.fromManagedJson]. Never bundle a key in a release.
typedef OpenRouterCredentialSource =
    Future<Result<OpenRouterCredential, AssistantFailure>> Function();

/// A short-lived, budget-limited OpenRouter key.
///
/// The key never appears in [toString], so it cannot leak through logs or
/// failure messages.
class OpenRouterCredential {
  const OpenRouterCredential({
    required String apiKey,
    this.allowedModels = const [],
    this.expiresAt,
    this.refreshAfter,
  }) : _apiKey = apiKey;

  /// Reads the body of asystant-api's `POST /v1/managed/credentials`.
  factory OpenRouterCredential.fromManagedJson(Map<String, Object?> json) =>
      OpenRouterCredential(
        apiKey: json['api_key'] as String,
        allowedModels: List.unmodifiable(
          (json['allowed_models'] as List<Object?>? ?? const []).cast<String>(),
        ),
        expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
        refreshAfter: DateTime.tryParse(json['refresh_after'] as String? ?? ''),
      );

  final String _apiKey;

  /// Models this key may use; empty when the source does not restrict them.
  final List<String> allowedModels;

  final DateTime? expiresAt;

  /// When to ask the source for a new key; defaults to [expiresAt].
  final DateTime? refreshAfter;

  /// The `Authorization` header value. Build it only when sending a request.
  String get authorization => 'Bearer $_apiKey';

  /// Whether the key can still be used at [now].
  bool usableAt(DateTime now) {
    final limit = refreshAfter ?? expiresAt;
    return _apiKey.isNotEmpty && (limit == null || limit.isAfter(now));
  }

  OpenRouterCredential copyWith({
    String? apiKey,
    List<String>? allowedModels,
    DateTime? expiresAt,
    DateTime? refreshAfter,
  }) => OpenRouterCredential(
    apiKey: apiKey ?? _apiKey,
    allowedModels: List.unmodifiable(allowedModels ?? this.allowedModels),
    expiresAt: expiresAt ?? this.expiresAt,
    refreshAfter: refreshAfter ?? this.refreshAfter,
  );

  @override
  bool operator ==(Object other) =>
      other is OpenRouterCredential &&
      _apiKey == other._apiKey &&
      const ListEquality<String>().equals(allowedModels, other.allowedModels) &&
      expiresAt == other.expiresAt &&
      refreshAfter == other.refreshAfter;

  @override
  int get hashCode => Object.hash(
    _apiKey,
    Object.hashAll(allowedModels),
    expiresAt,
    refreshAfter,
  );

  @override
  String toString() => 'OpenRouterCredential([REDACTED])';
}
