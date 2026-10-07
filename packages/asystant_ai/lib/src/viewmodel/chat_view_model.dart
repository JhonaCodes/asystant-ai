import 'dart:async';
import 'dart:math';

import 'package:asystant_core/asystant_core.dart';
import 'package:collection/collection.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/model/asystant_action_policy.dart';
import 'package:asystant_ai/src/model/assistant_step.dart';
import 'package:asystant_ai/src/model/asystant_model_option.dart';
import 'package:asystant_ai/src/model/asystant_turn_limits.dart';
import 'package:asystant_ai/src/model/chat_entry.dart';
import 'package:asystant_ai/src/model/conversation_snapshot.dart';
import 'package:asystant_ai/src/model/private_input_request.dart';
import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/service/asystant_conversation_store.dart';
import 'package:asystant_ai/src/service/asystant_file_picker.dart';
import 'package:asystant_ai/src/service/chat_secret_vault.dart';

part 'chat_view_model_lifecycle.dart';
part 'chat_view_model_conversations.dart';
part 'chat_view_model_composition.dart';
part 'chat_view_model_turn.dart';
part 'chat_view_model_tools.dart';

/// Decides whether [tool] waits for the person's approval before a call runs.
///
/// Asked on every call, after the tool's preview and before it runs; see
/// `AsystantAI.requiresConfirmation`.
typedef AsystantConfirmationPolicy = bool Function(AsystantTool tool);

/// Classifies each invocation after argument validation and before preview.
typedef AsystantActionPolicyResolver = AsystantActionPolicy Function(
  AsystantTool tool,
  ToolArguments arguments,
);

/// Owns conversation state and executes only registered, authorized local tools.
///
/// The responsibilities are split across five private mixins, each in its
/// own file (`part of` this library): [_ChatLifecycle] (configuration and
/// teardown), [_ChatConversations] (listing, opening, saving),
/// [_ChatComposition] (draft, model and attachments), [_ChatTurn] (sending a
/// message and streaming the response) and [_ChatTools] (local tool calls
/// and approvals). This class itself only holds what none of the five own:
/// the constructor, the host text bundle, and the small getters derived from
/// state that more than one mixin reads.
class ChatViewModel extends ViewModel<ChatState>
    with
        _ChatLifecycle,
        _ChatConversations,
        _ChatComposition,
        _ChatTurn,
        _ChatTools {
  ChatViewModel() : super(const ChatState());

  AsystantStrings _strings = AsystantStrings.english;

  /// The current host text bundle for labels created while a tool runs.
  void setStrings(AsystantStrings strings) => _strings = strings;

  @override
  ChatState get state => data;

  bool get isInitialized => _initialized;

  bool get canSend =>
      _initialized &&
      !state.busy &&
      (state.draft.trim().isNotEmpty || state.attachments.isNotEmpty);

  /// The person can prepare the next message while a turn runs; only an
  /// action waiting for a decision locks the field.
  @override
  bool get canType =>
      _initialized && state.pending == null && state.privateInput == null;

  /// The files the assistant accepts unless a chat surface overrides them.
  AsystantAttachmentPolicy get attachmentPolicy => _attachmentPolicy;
  bool get isAuthenticated => _transport?.isAuthenticated ?? false;

  /// New, open and delete wait until the current turn ends or is stopped.
  @override
  bool get canManageConversations => _initialized && !state.busy;

  /// The store keeps each identity's conversations apart.
  @override
  String get _scope => _identity ?? '';
}
