import 'package:asystant_core/asystant_core.dart';

import 'service/asystant_service.dart';

/// Extend in the host application; register local tools after host authentication.
abstract class AsystantAI with AsystantService {
  AsystantAI({this.name = 'Asistente'});

  /// Visible assistant name chosen by the host app.
  final String name;

  /// Local application tools to register during initialization.
  List<AsystantTool> get tools;

  /// Product-specific instructions registered alongside tool schemas.
  List<AsystantSystemPrompt> get systemPrompts => const [];

  /// Whether tool registration and model assignment have completed.
  bool get isInitialized => conversation.notifier.isInitialized;

  /// Whether the configured transport has a valid host login.
  bool get isAuthenticated => conversation.notifier.isAuthenticated;

  /// Initializes after host authentication; an empty model list accepts server policy.
  Future<void> init({
    required AssistantTransport transport,
    List<String> models = const [],
    List<AsystantTool> builtInTools = const [],
  }) => conversation.notifier.configure(
    transport: transport,
    tools: [...builtInTools, ...tools],
    prompts: systemPrompts,
    models: models,
  );

  /// Releases this instance and invalidates pending local actions.
  void dispose() => conversation.dispose();
}
