import 'package:reactive_notifier/reactive_notifier.dart';

import '../model/chat_state.dart';
import '../viewmodel/chat_view_model.dart';

/// One container per assistant, owned by the host rather than the chat widget.
mixin AsystantService {
  final ReactiveNotifierViewModel<ChatViewModel, ChatState> conversation =
      ReactiveNotifierViewModel(ChatViewModel.new);
}
