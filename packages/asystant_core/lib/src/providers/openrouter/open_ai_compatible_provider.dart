part of '../asystant_provider.dart';

/// A user supplied OpenAI-compatible Chat Completions endpoint.
///
/// The host supplies credentials; this variant does not persist keys. Flutter
/// hosts can use `AsystantProviderSettings` for encrypted local storage.
final class OpenAICompatibleProvider extends AsystantProvider {
  const OpenAICompatibleProvider({
    required this.credentials,
    required this.baseUri,
    required this.providerName,
    required this.model,
    this.identity,
    this.sessionChanges,
  });

  final OpenRouterCredentialSource credentials;
  final Uri baseUri;
  final String providerName;
  final String model;
  final String? Function()? identity;
  final Stream<void>? sessionChanges;

  @override
  String get name => providerName;

  @override
  AssistantTransport createTransport() => OpenRouterTransport(
    credentials: credentials,
    baseUri: baseUri,
    identity: identity,
    sessionChanges: sessionChanges,
    compatibilityMode: true,
    providerName: providerName,
    preferredModel: model,
  );

  @override
  String toString() =>
      'OpenAICompatibleProvider($providerName, [endpoint redacted])';
}
