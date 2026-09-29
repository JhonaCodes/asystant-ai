part of 'ai.dart';

/// The one assistant of the app, created on first use and kept for the
/// app's lifetime so conversations survive closing the chat.
mixin _AiService {
  static final ReactiveNotifier<_BotanicaAssistant> assistant =
      ReactiveNotifier<_BotanicaAssistant>(_BotanicaAssistant.connected);
}
