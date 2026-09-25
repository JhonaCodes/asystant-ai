import 'dart:async';
import 'dart:math';

import 'package:asystant_core/asystant_core.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/model/assistant_step.dart';
import 'package:asystant_ai/src/model/chat_entry.dart';

/// Owns conversation state and executes only registered, authorized local tools.
class ChatViewModel extends ViewModel<ChatState> {
  ChatViewModel() : super(const ChatState());

  static const _streamingInterval = Duration(milliseconds: 32);

  AssistantTransport? _transport;

  ToolRegistry? _registry;

  StreamSubscription<void>? _session;

  Completer<bool>? _approval;

  int _epoch = 0;

  bool _closed = false;

  bool _initialized = false;

  String? _identity;

  final Set<String> _executed = {};

  final StringBuffer _streamingText = StringBuffer();

  Timer? _streamingTimer;

  @override
  void init() {}

  ChatState get state => data;

  bool get isInitialized => _initialized;

  bool get canSend =>
      _initialized && !state.busy && state.draft.trim().isNotEmpty;
  bool get isAuthenticated => _transport?.isAuthenticated ?? false;

  Future<void> configure({
    required AssistantTransport transport,
    required List<AsystantTool> tools,
    required List<AsystantSystemPrompt> prompts,
    required List<String> models,
  }) async {
    if (_closed || state.busy || state.phase == ChatPhase.initializing) {
      return;
    }
    final epoch = ++_epoch;
    _initialized = false;
    final previousTransport = _transport;
    _transport = transport;
    updateState(const ChatState(phase: ChatPhase.initializing));
    await _session?.cancel();
    if (previousTransport != null && previousTransport != transport) {
      await previousTransport.dispose();
    }
    if (_closed || epoch != _epoch) {
      return;
    }
    _registry = ToolRegistry(tools);
    _identity = transport.identity;
    _session = transport.sessionChanges.listen((_) {
      if (_identity != transport.identity) {
        cancel();
        _initialized = false;
        _identity = transport.identity;
        _executed.clear();
        updateState(const ChatState(phase: ChatPhase.idle));
      }
    });
    final validation = _registry!.validate();
    if (validation.isErr) {
      _fail(validation.errorOrNull!);
      return;
    }
    final promptPolicy = const AsystantPromptPolicy().compose(prompts);
    final configuredPrompts = promptPolicy.when(
      ok: (composed) => composed,
      err: (failure) {
        _fail(failure);
        return null;
      },
    );
    if (configuredPrompts == null) {
      return;
    }

    try {
      final result = await transport.initialize(
        tools: tools
            .where((t) => t.isAvailable)
            .map((t) => t.definition)
            .toList(),
        prompts: configuredPrompts,
        models: models,
      );
      if (!_current(epoch)) {
        return;
      }
      result.when(
        ok: (allowed) {
          if (allowed.isEmpty) {
            _fail(const AssistantFailure(.unavailable));
            return;
          }
          _initialized = true;
          updateState(
            state.copyWith(
              phase: .ready,
              models: allowed,
              model: transport.defaultModel ?? allowed.first,
              allowModelSelection: transport.allowModelSelection,
            ),
          );
        },
        err: _fail,
      );
    } catch (_) {
      if (_current(epoch)) {
        _fail(const AssistantFailure(.unavailable));
      }
    }
  }

  /// Keeps unexpected host registration errors inside the assistant surface.
  void reportInitializationFailure() {
    if (!_closed) {
      _initialized = false;
      _fail(const AssistantFailure(.unavailable));
    }
  }

  bool _current(int epoch) =>
      !_closed && epoch == _epoch && _identity == _transport?.identity;
  void setDraft(String value) {
    if (!_closed) {
      updateState(state.copyWith(draft: value));
    }
  }

  void selectModel(String model) {
    if (state.allowModelSelection &&
        !state.busy &&
        state.models.contains(model)) {
      updateState(state.copyWith(model: model));
    }
  }

  void selectOption(String option) {
    final pending = state.pending;
    if (pending == null || !pending.card.options.contains(option)) {
      return;
    }
    final selected = [...pending.selected];
    selected.contains(option) ? selected.remove(option) : selected.add(option);
    updateState(state.copyWith(pending: pending.copyWith(selected: selected)));
  }

  void approve(bool allow) {
    final pending = state.pending;
    if (pending == null) {
      return;
    }
    final tool = _registry
        ?.resolve(pending.call.name, pending.call.arguments)
        .when(ok: (t) => t, err: (_) => null);
    if (allow && tool?.requiresSelection == true && pending.selected.isEmpty) {
      return;
    }
    if (_approval?.isCompleted == false) {
      _approval?.complete(allow);
    }
  }

  void cancel() {
    _epoch++;
    _resetStreaming();
    _transport?.cancel();
    if (_approval?.isCompleted == false) {
      _approval?.complete(false);
    }
    _approval = null;
    if (!_closed) {
      updateState(
        state.copyWith(
          phase: .canceled,
          steps: _endSteps(StepPhase.canceled),
          messages: _closePendingCalls(),
          streaming: '',
          clearPending: true,
        ),
      );
    }
  }

  List<AssistantMessage> _closePendingCalls() {
    final pending = <String>{};
    for (final message in state.messages) {
      pending.addAll(message.calls.map((call) => call.id));
      if (message.role == MessageRole.tool) {
        pending.remove(message.callId);
      }
    }
    return [
      ...state.messages,
      for (final id in pending)
        AssistantMessage(
          role: MessageRole.tool,
          content: 'Operation interrupted. Outcome may be unknown; inspect app state before proposing another write.',
          callId: id,
        ),
    ];
  }

  void _fail(AssistantFailure failure) {
    _resetStreaming();
    updateState(
      state.copyWith(
        phase: .error,
        steps: _endSteps(StepPhase.failed),
        messages: _closePendingCalls(),
        draft:
            failure.code == FailureCode.network &&
                state.draft.isEmpty &&
                state.messages.isNotEmpty &&
                state.messages.last.role == MessageRole.user
            ? state.messages.last.content
            : state.draft,
        failure: failure,
        streaming: '',
        clearPending: true,
      ),
    );
  }

  List<AssistantStep> _endSteps(StepPhase phase) => state.steps
      .map((step) => step.active ? step.copyWith(phase: phase) : step)
      .toList();
  void _step(String id, StepPhase phase, {String? title}) {
    final exists = state.steps.any((step) => step.id == id);
    updateState(
      state.copyWith(
        steps: exists
            ? state.steps
                  .map(
                    (step) => step.id == id
                        ? step.copyWith(phase: phase, title: title)
                        : step,
                  )
                  .toList()
            : [
                ...state.steps,
                AssistantStep(id: id, title: title ?? '', phase: phase),
              ],
      ),
    );
  }

  Future<void> send([String? text]) async {
    final content = (text ?? state.draft).trim();
    if (!_initialized || state.busy || content.isEmpty || _transport == null) {
      return;
    }
    final epoch = ++_epoch;
    _resetStreaming();
    final random = Random.secure();
    final turn = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    updateState(
      state.copyWith(
        phase: .thinking,
        steps: const [],
        entries: [
          ...state.entries,
          ChatEntry(
            message: AssistantMessage(role: .user, content: content),
          ),
        ],
        messages: [
          ...state.messages,
          AssistantMessage(role: .user, content: content),
        ],
        draft: '',
        streaming: '',
        clearPending: true,
        clearFailure: true,
      ),
    );
    try {
      for (var round = 0; round < 8; round++) {
        AssistantMessage? completed;
        var failed = false;
        await for (final event in _transport!.infer(
          messages: state.messages,
          model: state.model,
          requestId: '$turn-$round',
        )) {
          if (!_current(epoch)) {
            return;
          }
          switch (event) {
            case TextDelta():
              _appendStreaming(event.text, epoch);
            case InferenceCompleted():
              if (completed != null ||
                  event.message.role != MessageRole.assistant) {
                failed = true;
                _fail(const AssistantFailure(.protocol));
              } else {
                completed = event.message;
              }
            case InferenceFailed():
              failed = true;
              _fail(event.failure);
            default:
              failed = true;
              _fail(const AssistantFailure(.protocol));
          }
          if (failed) {
            break;
          }
        }
        if (!_current(epoch) || failed) {
          return;
        }
        if (completed == null) {
          _fail(const AssistantFailure(.protocol));
          return;
        }
        final response = completed;
        final ids = response.calls.map((c) => c.id).toSet();
        if (ids.length != response.calls.length ||
            ids.contains('') ||
            response.calls.length > 16) {
          _fail(const AssistantFailure(.protocol));
          return;
        }
        _resetStreaming();
        updateState(
          state.copyWith(
            entries: [
              ...state.entries,
              if (response.content.isNotEmpty) ChatEntry(message: response),
            ],
            messages: [...state.messages, response],
            streaming: '',
          ),
        );
        if (response.calls.isEmpty) {
          updateState(state.copyWith(phase: .done));
          return;
        }
        for (final call in response.calls) {
          await _executeLocalCall(call, turn, epoch);
          if (!_current(epoch)) {
            return;
          }
        }
        updateState(state.copyWith(phase: .thinking));
      }
      _fail(const AssistantFailure(.limit));
    } catch (_) {
      if (_current(epoch)) {
        _fail(const AssistantFailure(.toolFailed));
      }
    }
  }

  /// Coalesces provider bursts without tying execution to a mounted chat or frame.
  /// The completed provider message remains the authoritative final response.
  void _appendStreaming(String text, int epoch) {
    _streamingText.write(text);
    _streamingTimer ??= Timer(_streamingInterval, () {
      _streamingTimer = null;
      if (_current(epoch)) {
        updateState(state.copyWith(streaming: _streamingText.toString()));
      }
    });
  }

  void _resetStreaming() {
    _streamingTimer?.cancel();
    _streamingTimer = null;
    _streamingText.clear();
  }

  /// Previews, authorizes and executes a single call against the frozen turn.
  /// Cancellation is checked again after every asynchronous host boundary.
  Future<void> _executeLocalCall(ToolCall call, String turn, int epoch) async {
    if (!_current(epoch)) {
      return;
    }
    final executionKey = '$turn/${call.id}';
    final tool = _registry!
        .resolve(call.name, call.arguments)
        .when(ok: (tool) => tool, err: (_) => null);
    var outcome = 'Tool unavailable or invalid arguments.';
    _step(
      executionKey,
      StepPhase.preparing,
      title: tool?.definition.description ?? call.name,
    );
    if (tool != null && !_executed.contains(executionKey)) {
      updateState(state.copyWith(phase: .executing));
      final preview = await tool.preview(call.arguments);
      if (!_current(epoch)) {
        return;
      }
      final card = preview.when(ok: (card) => card, err: (_) => null);
      if (card != null) {
        _step(executionKey, StepPhase.preparing, title: card.title);
        var allowed = !tool.requiresConfirmation && !tool.requiresSelection;
        var selected = <String>[];
        if (!allowed) {
          _step(executionKey, StepPhase.permission);
          _approval = Completer<bool>();
          updateState(
            state.copyWith(
              phase: .permission,
              pending: PendingAction(
                call: call,
                card: card,
                requiresSelection: tool.requiresSelection,
              ),
            ),
          );
          allowed = await _approval!.future;
          selected = state.pending?.selected.toList() ?? [];
          if (!_current(epoch)) {
            return;
          }
          _approval = null;
          updateState(state.copyWith(clearPending: true));
        }
        if (allowed && tool.isAvailable) {
          _step(executionKey, StepPhase.running);
          _executed.add(executionKey);
          updateState(state.copyWith(phase: .executing));
          final result = await tool.execute(
            call.arguments,
            ToolContext(
              idempotencyKey: executionKey,
              selectedOptions: List.unmodifiable(selected),
              isCanceled: () => !_current(epoch),
            ),
          );
          if (!_current(epoch)) {
            return;
          }
          result.when(
            ok: (result) {
              _step(executionKey, StepPhase.completed);
              outcome = result.modelContent;
              if (result.card case final card?) {
                updateState(
                  state.copyWith(
                    cards: [...state.cards, card],
                    entries: [
                      ...state.entries,
                      ChatEntry(card: card),
                    ],
                  ),
                );
              }
            },
            err: (_) {
              _step(executionKey, StepPhase.failed);
              outcome = 'Local tool failed. Do not assume it succeeded.';
            },
          );
        } else {
          _step(executionKey, StepPhase.declined);
          outcome = 'User declined this action. Do not repeat it without a new request.';
        }
      } else {
        _step(executionKey, StepPhase.failed);
        outcome = 'Could not prepare a safe preview.';
      }
    }
    if (state.steps.any((step) => step.id == executionKey && step.active)) {
      _step(executionKey, StepPhase.failed);
    }
    updateState(
      state.copyWith(
        messages: [
          ...state.messages,
          AssistantMessage(role: .tool, content: outcome, callId: call.id),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_closed) {
      return;
    }
    cancel();
    _closed = true;
    unawaited(_session?.cancel());
    unawaited(_transport?.dispose());
    super.dispose();
  }
}
