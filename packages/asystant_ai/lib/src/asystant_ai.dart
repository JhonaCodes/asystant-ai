import 'package:asystant_core/asystant_core.dart';

import 'service/asystant_service.dart';

/// Extend in the host application; register local tools after host authentication.
abstract class AsystantAI with AsystantService {
  AsystantAI({this.name = 'Asistente'});
  final String name;
  List<AsystantTool> get tools;
  List<AsystantSystemPrompt> get systemPrompts => const [];
  bool get isInitialized => conversation.notifier.isInitialized;
  bool get isAuthenticated => conversation.notifier.isAuthenticated;
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
  void dispose() => conversation.dispose();
}
