part of '../ai.dart';

/// The assistant: its name, its instructions and the tools it may call.
final class _BotanicaAssistant extends AsystantAI {
  _BotanicaAssistant()
    : super(name: 'Botánica', description: 'Asistente de plantas medicinales');

  /// A configured assistant, ready to open in the chat.
  factory _BotanicaAssistant.connected() => _BotanicaAssistant()
    ..init(
      transport: _AiConnection.transport(),
      models: _AiConnection.models,
      attachments: _AiConnection.attachments,
    );

  @override
  List<AsystantTool> get tools => _BotanicaTools.all;

  @override
  List<AsystantSystemPrompt> get systemPrompts => const [
    _BotanicaPrompts.role,
    _BotanicaPrompts.interview,
    _BotanicaPrompts.recommend,
    _BotanicaPrompts.safety,
  ];

  /// What it knows about the person, fresh for every answer.
  @override
  Future<List<AsystantSystemPrompt>> contextPrompts() =>
      _PersonContext.prompts();
}
