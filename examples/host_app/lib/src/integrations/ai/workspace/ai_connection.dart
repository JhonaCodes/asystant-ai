part of '../ai.dart';

/// How the assistant reaches the model, and which files it accepts.
abstract final class _AiConnection {
  /// Read from `.env` with `flutter run --dart-define-from-file=.env`.
  ///
  /// Only for local testing with a short-lived key. A published app gets a
  /// budget-limited key from its backend (asystant-api,
  /// `POST /v1/managed/credentials`) and never compiles one into the build.
  static const _openRouterKey = String.fromEnvironment('OPENROUTER_API_KEY');

  /// Where the answers come from. Another provider, such as
  /// `ClaudeCodeProvider()` on a desktop build, changes only this line:
  /// tools, prompts, context and cards stay as they are.
  static AsystantProvider provider() {
    if (_openRouterKey.isEmpty) {
      // The chat still opens and shows that it cannot connect.
      Log.w(
        'OPENROUTER_API_KEY is missing: run with --dart-define-from-file=.env',
      );
    }
    return OpenRouterProvider(
      credentials: () async => _openRouterKey.isEmpty
          ? Err(const AssistantFailure(.authentication))
          : Ok(OpenRouterCredential(apiKey: _openRouterKey)),
      appName: 'Botánica',
    );
  }

  /// The levels the person picks next to Send; the first is the default.
  static const models = [
    AsystantModelOption(
      id: 'openai/gpt-oss-120b',
      label: 'Preciso',
      icon: Icons.psychology_outlined,
      description: 'Piensa más y responde con más detalle',
    ),
    AsystantModelOption(
      id: 'openai/gpt-oss-20b',
      label: 'Rápido',
      icon: Icons.bolt_outlined,
      description: 'Respuestas cortas y ágiles',
    ),
  ];

  /// Photos only: of a plant to identify or of the area that bothers the
  /// person.
  static final attachments = AsystantAttachmentPolicy(
    allowedExtensions: AsystantFileTypes.images,
    maxFiles: 4,
  );
}
