import 'package:reactive_notifier/reactive_notifier.dart';

import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/viewmodel/chat_view_model.dart';

/// Lazily owns one conversation per assistant, independent of widget lifetime.
mixin AsystantService {
  ReactiveNotifierViewModel<ChatViewModel, ChatState>? _conversation;

  /// Creates the reactive container only when the conversation is accessed.
  ReactiveNotifierViewModel<ChatViewModel, ChatState> get conversation =>
      _conversation ??= ReactiveNotifierViewModel(ChatViewModel.new);

  /// Releases an existing conversation without creating one during cleanup.
  void disposeConversation() => _conversation?.dispose();
}
