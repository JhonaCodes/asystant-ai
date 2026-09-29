part of '../asystant_provider.dart';

/// Models on OpenRouter, called directly from the app with the signed-in
/// user's short-lived, budget-limited key.
///
/// In production [credentials] asks the host's backend, which obtains the
/// key from asystant-api; see [OpenRouterCredential.fromManagedJson]. The
/// key is cached, refreshed and only ever sent in the `Authorization`
/// header; see [OpenRouterTransport].
///
/// ```dart
/// assistant.init(
///   provider: OpenRouterProvider(
///     credentials: fetchAiCredential,
///     identity: () => session.userId,
///     sessionChanges: session.changes,
///     appName: 'Workspace',
///   ),
/// );
/// ```
final class OpenRouterProvider extends AsystantProvider {
  const OpenRouterProvider({
    required this.credentials,
    this.identity,
    this.sessionChanges,
    this.appName,
    this.appUrl,
    this.baseUri,
    this.maxOutputTokens,
    this.temperature,
    this.pdfEngine = 'pdf-text',
  });

  /// Returns the signed-in user's key.
  final OpenRouterCredentialSource credentials;

  /// The current login, or null when signed out; a fixed `'local'` when
  /// null itself.
  final String? Function()? identity;

  /// Emits whenever the login changes.
  final Stream<void>? sessionChanges;

  /// Sent as `X-Title` so usage is attributed to the app in OpenRouter.
  final String? appName;

  /// Sent as `HTTP-Referer` together with [appName].
  final String? appUrl;

  /// OpenRouter's API root; override it for a compatible proxy.
  final Uri? baseUri;

  /// Upper bound for each response; the model's default when null.
  final int? maxOutputTokens;

  final double? temperature;

  /// How attached PDFs are read: `pdf-text`, `mistral-ocr` or `native`.
  final String pdfEngine;

  @override
  String get name => 'OpenRouter';

  @override
  AssistantTransport createTransport() => OpenRouterTransport(
    credentials: credentials,
    identity: identity,
    sessionChanges: sessionChanges,
    appName: appName,
    appUrl: appUrl,
    baseUri: baseUri,
    maxOutputTokens: maxOutputTokens,
    temperature: temperature,
    pdfEngine: pdfEngine,
  );

  OpenRouterProvider copyWith({
    OpenRouterCredentialSource? credentials,
    String? Function()? identity,
    Stream<void>? sessionChanges,
    String? appName,
    String? appUrl,
    Uri? baseUri,
    int? maxOutputTokens,
    double? temperature,
    String? pdfEngine,
  }) => OpenRouterProvider(
    credentials: credentials ?? this.credentials,
    identity: identity ?? this.identity,
    sessionChanges: sessionChanges ?? this.sessionChanges,
    appName: appName ?? this.appName,
    appUrl: appUrl ?? this.appUrl,
    baseUri: baseUri ?? this.baseUri,
    maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
    temperature: temperature ?? this.temperature,
    pdfEngine: pdfEngine ?? this.pdfEngine,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpenRouterProvider &&
          credentials == other.credentials &&
          identity == other.identity &&
          sessionChanges == other.sessionChanges &&
          appName == other.appName &&
          appUrl == other.appUrl &&
          baseUri == other.baseUri &&
          maxOutputTokens == other.maxOutputTokens &&
          temperature == other.temperature &&
          pdfEngine == other.pdfEngine;

  @override
  int get hashCode => Object.hash(
    credentials,
    identity,
    sessionChanges,
    appName,
    appUrl,
    baseUri,
    maxOutputTokens,
    temperature,
    pdfEngine,
  );

  /// The credential source is a function: nothing secret to print.
  @override
  String toString() => 'OpenRouterProvider(${baseUri ?? 'openrouter.ai'})';
}
