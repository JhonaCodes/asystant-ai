import 'dart:async';
import 'dart:math';

import 'package:asystant_core/asystant_core.dart';
import 'package:collection/collection.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/model/assistant_step.dart';
import 'package:asystant_ai/src/model/asystant_model_option.dart';
import 'package:asystant_ai/src/model/asystant_turn_limits.dart';
import 'package:asystant_ai/src/model/chat_entry.dart';
import 'package:asystant_ai/src/model/conversation_snapshot.dart';
import 'package:asystant_ai/src/service/asystant_conversation_store.dart';
import 'package:asystant_ai/src/service/asystant_file_picker.dart';

/// Owns conversation state and executes only registered, authorized local tools.
class ChatViewModel extends ViewModel<ChatState> {
  ChatViewModel() : super(const ChatState());

  static const _streamingInterval = Duration(milliseconds: 32);

  AssistantTransport? _transport;

  ToolRegistry? _registry;

  StreamSubscription<void>? _session;

  AsystantConversationStore _store = InMemoryConversationStore();

  Completer<bool>? _approval;

  int _epoch = 0;

  bool _closed = false;

  bool _initialized = false;

  String? _identity;

  final Set<String> _executed = {};

  final StringBuffer _streamingText = StringBuffer();

  Timer? _streamingTimer;

  AsystantAttachmentPolicy _attachmentPolicy = const AsystantAttachmentPolicy();

  /// Rounds per turn and calls per response; see [AsystantTurnLimits].
  AsystantTurnLimits _turnLimits = const AsystantTurnLimits();

  /// What the host knows now; read again before every model call.
  AsystantContextSource _context = _noContext;

  static Future<List<AsystantSystemPrompt>> _noContext() async => const [];

  /// When the last message went out; see [stop].
  DateTime? _sentAt;

  static const _stopGuard = Duration(milliseconds: 600);

  @override
  void init() {}

  ChatState get state => data;

  bool get isInitialized => _initialized;

  bool get canSend =>
      _initialized &&
      !state.busy &&
      (state.draft.trim().isNotEmpty || state.attachments.isNotEmpty);

  /// The person can prepare the next message while a turn runs; only an
  /// action waiting for a decision locks the field.
  bool get canType => _initialized && state.pending == null;

  /// The files the assistant accepts unless a chat surface overrides them.
  AsystantAttachmentPolicy get attachmentPolicy => _attachmentPolicy;
  bool get isAuthenticated => _transport?.isAuthenticated ?? false;

  /// New, open and delete wait until the current turn ends or is stopped.
  bool get canManageConversations => _initialized && !state.busy;

  /// The store keeps each identity's conversations apart.
  String get _scope => _identity ?? '';

  Future<void> configure({
    required AssistantTransport transport,
    required List<AsystantTool> tools,
    required List<AsystantSystemPrompt> prompts,
    required List<AsystantModelOption> models,
    AsystantConversationStore? store,
    AsystantAttachmentPolicy attachmentPolicy =
        const AsystantAttachmentPolicy(),
    AsystantContextSource? context,
    AsystantTurnLimits turnLimits = const AsystantTurnLimits(),
  }) async {
    turnLimits.validate();
    if (_closed || state.busy || state.phase == ChatPhase.initializing) {
      return;
    }
    final epoch = ++_epoch;
    _initialized = false;
    final previousTransport = _transport;
    _transport = transport;
    if (store != null) {
      _store = store;
    }
    _attachmentPolicy = attachmentPolicy;
    _turnLimits = turnLimits;
    _context = context ?? _noContext;
    // A retry for the same person keeps the conversations; anyone else
    // starts clean.
    final sameIdentity = _identity != null && _identity == transport.identity;
    updateState(
      sameIdentity
          ? state.copyWith(phase: ChatPhase.initializing, clearFailure: true)
          : ChatState(phase: ChatPhase.initializing, conversationId: _newId()),
    );
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
        unawaited(_store.clear(_scope));
        _identity = transport.identity;
        _executed.clear();
        updateState(ChatState(phase: ChatPhase.idle, conversationId: _newId()));
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
        models: [for (final option in models) option.id],
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
              model: allowed.contains(state.model)
                  ? state.model
                  : transport.defaultModel ?? allowed.first,
              allowModelSelection: transport.allowModelSelection,
              contextLengths: {
                for (final model in allowed)
                  if (transport.contextLengthOf(model) case final int length)
                    model: length,
              },
              modelOptions: [
                for (final id in allowed)
                  models.firstWhereOrNull((option) => option.id == id) ??
                      AsystantModelOption.fallback(id),
              ],
            ),
          );
        },
        err: _fail,
      );
      if (_initialized && _current(epoch)) {
        await _loadSavedConversations(epoch);
      }
    } catch (_) {
      if (_current(epoch)) {
        _fail(const AssistantFailure(.unavailable));
      }
    }
  }

  /// Lists what the store kept for this identity, next to the one on screen.
  Future<void> _loadSavedConversations(int epoch) async {
    final saved = await _store.list(_scope);
    if (!_current(epoch)) {
      return;
    }
    saved.when(
      ok: (summaries) => updateState(
        state.copyWith(
          conversations: {
            for (final summary in [...summaries, ...state.conversations])
              summary.id: summary,
          }.values.sorted((a, b) => b.updatedAt.compareTo(a.updatedAt)),
        ),
      ),
      err: (_) {},
    );
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

  /// The model belongs to the conversation; a new one keeps the last choice.
  void selectModel(String model) {
    if (state.allowModelSelection &&
        !state.busy &&
        state.models.contains(model)) {
      // An empty conversation has no row yet; choosing a model adds none.
      final saved = state.conversations.any(
        (summary) => summary.id == state.conversationId,
      );
      updateState(
        state.copyWith(
          model: model,
          conversations: saved
              ? _withActive((summary) => summary.copyWith(model: model))
              : null,
        ),
      );
    }
  }

  // ------------------------------------------------------------ attachments

  /// Adds [file] to the next message if [policy] (the assistant's by
  /// default) accepts it; otherwise records why not and returns the reason.
  AttachmentIssue? attach(
    AsystantAttachment file, {
    AsystantAttachmentPolicy? policy,
  }) {
    if (_closed) {
      return AttachmentIssue.disabled;
    }
    final issue = (policy ?? _attachmentPolicy).issueFor(
      filename: file.filename,
      size: file.size,
      pending: state.attachments.length,
    );
    updateState(
      issue == null
          ? state.copyWith(
              attachments: [...state.attachments, file],
              clearAttachmentIssue: true,
            )
          : state.copyWith(attachmentIssue: issue),
    );
    return issue;
  }

  /// Opens [picker] (the system one by default) and attaches what it
  /// returns, within [policy] (the assistant's by default).
  Future<void> pickAttachments({
    AsystantAttachmentPolicy? policy,
    AsystantFilePick? picker,
  }) async {
    final rules = policy ?? _attachmentPolicy;
    if (_closed || !rules.enabled) {
      return;
    }
    final free = rules.maxFiles - state.attachments.length;
    if (free <= 0) {
      rejectAttachment(AttachmentIssue.tooMany);
      return;
    }
    final picked = await (picker ?? AsystantFilePicker.pick)(
      rules.copyWith(maxFiles: free),
    );
    if (_closed) {
      return;
    }
    for (final file in picked.files) {
      attach(file, policy: rules);
    }
    if (picked.issue case final issue?) {
      rejectAttachment(issue);
    }
  }

  /// Shows why a file could not be attached, e.g. it could not be read.
  void rejectAttachment(AttachmentIssue issue) {
    if (!_closed) {
      updateState(state.copyWith(attachmentIssue: issue));
    }
  }

  void removeAttachment(String id) {
    if (!_closed) {
      updateState(
        state.copyWith(
          attachments: state.attachments
              .where((file) => file.id != id)
              .toList(),
          clearAttachmentIssue: true,
        ),
      );
    }
  }

  /// Stops the turn, except right after sending: a double tap on Send must
  /// not cancel the message it just sent.
  void stop() {
    final sentAt = _sentAt;
    if (sentAt != null && DateTime.now().difference(sentAt) < _stopGuard) {
      return;
    }
    cancel();
  }

  // ---------------------------------------------------------- conversations

  /// Starts an empty conversation; an empty one on screen is reused.
  Future<void> newConversation() async {
    if (!canManageConversations || state.messages.isEmpty) {
      return;
    }
    await _saveActive();
    if (_closed || !canManageConversations) {
      return;
    }
    _showConversation(id: _newId());
  }

  /// Shows [id], keeping the conversation on screen in the store.
  Future<void> openConversation(String id) async {
    if (!canManageConversations || id == state.conversationId) {
      return;
    }
    await _saveActive();
    final snapshot = await _store.read(_scope, id);
    if (_closed || !canManageConversations) {
      return;
    }
    snapshot.when(
      ok: (snapshot) => _showConversation(
        id: snapshot.summary.id,
        messages: snapshot.messages,
        entries: snapshot.entries,
        model: snapshot.summary.model,
        usage: snapshot.summary.usage,
      ),
      err: (_) => updateState(
        state.copyWith(
          conversations: state.conversations
              .where((summary) => summary.id != id)
              .toList(),
        ),
      ),
    );
  }

  /// Deletes [id]; deleting the one on screen also clears it.
  Future<void> deleteConversation(String id) async {
    if (!canManageConversations) {
      return;
    }
    await _store.delete(_scope, id);
    if (_closed || !canManageConversations) {
      return;
    }
    final remaining = state.conversations
        .where((summary) => summary.id != id)
        .toList();
    updateState(state.copyWith(conversations: remaining));
    if (id != state.conversationId) {
      return;
    }
    _showConversation(id: _newId());
  }

  Future<void> _saveActive() async {
    final summary = state.conversations.firstWhereOrNull(
      (summary) => summary.id == state.conversationId,
    );
    if (summary == null) {
      return;
    }
    await _store.write(
      _scope,
      ConversationSnapshot(
        summary: summary,
        messages: state.messages,
        entries: state.entries,
      ),
    );
  }

  void _showConversation({
    required String id,
    List<AssistantMessage> messages = const [],
    List<ChatEntry> entries = const [],
    String? model,
    TokenUsage? usage,
  }) {
    _resetStreaming();
    updateState(
      state.copyWith(
        phase: .ready,
        conversationId: id,
        messages: messages,
        entries: entries,
        cards: const [],
        steps: const [],
        streaming: '',
        draft: '',
        model: model != null && state.models.contains(model)
            ? model
            : state.model,
        usage: usage,
        clearUsage: usage == null,
        clearPending: true,
        clearFailure: true,
      ),
    );
  }

  /// The list with the active conversation changed by [change], newest first.
  List<ConversationSummary> _withActive(
    ConversationSummary Function(ConversationSummary summary) change,
  ) {
    final now = DateTime.now();
    final current =
        state.conversations.firstWhereOrNull(
          (summary) => summary.id == state.conversationId,
        ) ??
        ConversationSummary(
          id: state.conversationId,
          title: '',
          model: state.model,
          createdAt: now,
          updatedAt: now,
        );
    return [
      change(current),
      ...state.conversations.where((summary) => summary.id != current.id),
    ].sorted((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  String _newId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
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
          entries: _archivedActivity(_endSteps(StepPhase.canceled)),
          steps: const [],
          messages: _closePendingCalls(),
          streaming: '',
          clearPending: true,
        ),
      );
      unawaited(_saveActive());
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

  /// Keeps what an interrupted turn did visible after it ends.
  List<ChatEntry> _archivedActivity(List<AssistantStep> steps) => [
    ...state.entries,
    if (steps.isNotEmpty) ChatEntry(activity: steps),
  ];

  void _fail(AssistantFailure failure) {
    _resetStreaming();
    updateState(
      state.copyWith(
        phase: .error,
        entries: _archivedActivity(_endSteps(StepPhase.failed)),
        steps: const [],
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
    unawaited(_saveActive());
  }

  List<AssistantStep> _endSteps(StepPhase phase) => state.steps
      .map((step) => step.active ? step.copyWith(phase: phase) : step)
      .toList();
  void _step(
    String id,
    StepPhase phase, {
    String? title,
    String? toolName,
    DateTime? startedAt,
    String? detail,
    Map<String, Object?>? data,
  }) {
    final exists = state.steps.any((step) => step.id == id);
    updateState(
      state.copyWith(
        steps: exists
            ? state.steps
                  .map(
                    (step) => step.id == id
                        ? step.copyWith(
                            phase: phase,
                            title: title,
                            toolName: toolName,
                            startedAt: startedAt,
                            detail: detail,
                            data: data,
                          )
                        : step,
                  )
                  .toList()
            : [
                ...state.steps,
                AssistantStep(
                  id: id,
                  title: title ?? '',
                  phase: phase,
                  toolName: toolName ?? '',
                  startedAt: startedAt,
                  detail: detail ?? '',
                  data: data ?? const {},
                ),
              ],
      ),
    );
  }

  Future<void> send([String? text]) async {
    final content = (text ?? state.draft).trim();
    final files = state.attachments;
    if (!_initialized ||
        state.busy ||
        (content.isEmpty && files.isEmpty) ||
        _transport == null) {
      return;
    }
    _sentAt = DateTime.now();
    final message = AssistantMessage(
      role: .user,
      content: content,
      attachments: files,
    );
    final epoch = ++_epoch;
    _resetStreaming();
    final turn = _newId();
    updateState(
      state.copyWith(
        phase: .thinking,
        steps: const [],
        conversations: _withActive(
          (summary) => summary.copyWith(
            title: summary.title.isEmpty
                ? ConversationSummary.excerpt(
                    content.isEmpty ? files.first.filename : content,
                  )
                : summary.title,
            model: state.model,
            updatedAt: DateTime.now(),
          ),
        ),
        entries: [
          ...state.entries,
          ChatEntry(message: message),
        ],
        messages: [...state.messages, message],
        draft: '',
        attachments: const [],
        clearAttachmentIssue: true,
        streaming: '',
        clearPending: true,
        clearFailure: true,
      ),
    );
    // Frozen for the turn, like its epoch.
    final limits = _turnLimits;
    try {
      for (var round = 0; round < limits.maxRounds; round++) {
        AssistantMessage? completed;
        var failed = false;
        // Read each round: a tool of the previous round may have changed it.
        final checked = const AsystantPromptPolicy().context(await _context());
        if (!_current(epoch)) {
          return;
        }
        final context = checked.when(
          ok: (prompts) => prompts,
          err: (_) => null,
        );
        if (context == null) {
          _fail(checked.errorOrNull ?? const AssistantFailure(.protocol));
          return;
        }
        // Also read each round: availability can depend on what the host
        // shows now, which a tool of the previous round may have changed.
        final available = [
          for (final tool in _registry!.tools)
            if (tool.isAvailable) tool.definition,
        ];
        await for (final event in _transport!.infer(
          messages: state.messages,
          model: state.model,
          requestId: '$turn-$round',
          context: context,
          tools: available,
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
            case UsageReported():
              updateState(
                state.copyWith(
                  usage: event.usage,
                  conversations: _withActive(
                    (summary) => summary.copyWith(usage: event.usage),
                  ),
                ),
              );
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
            response.calls.length > limits.maxCallsPerResponse) {
          _fail(const AssistantFailure(.protocol));
          return;
        }
        _resetStreaming();
        final finished = response.calls.isEmpty;
        // The final answer carries what the turn did before it.
        final activity = finished ? state.steps : const <AssistantStep>[];
        updateState(
          state.copyWith(
            entries: [
              ...state.entries,
              if (response.content.isNotEmpty || activity.isNotEmpty)
                ChatEntry(message: response, activity: activity),
            ],
            messages: [...state.messages, response],
            steps: finished ? const [] : null,
            streaming: '',
            phase: finished ? .done : null,
          ),
        );
        if (finished) {
          unawaited(_saveActive());
          return;
        }
        for (final (index, call) in response.calls.indexed) {
          final endsTurn = await _executeLocalCall(call, turn, epoch);
          if (!_current(epoch)) {
            return;
          }
          if (endsTurn) {
            _endTurnAt(call, skipped: response.calls.skip(index + 1));
            return;
          }
        }
        updateState(state.copyWith(phase: .thinking));
      }
      // The last round's calls ran and their results are in the history,
      // but the model is not asked again.
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

  /// Ends the turn after [call], whose tool asked for it
  /// (`ToolOutcome.endsTurn`): the calls in [skipped] are answered without
  /// running, and the model is not called again. The person speaks next.
  void _endTurnAt(ToolCall call, {required Iterable<ToolCall> skipped}) {
    updateState(
      state.copyWith(
        phase: .done,
        entries: _archivedActivity(state.steps),
        steps: const [],
        messages: [
          ...state.messages,
          for (final other in skipped)
            AssistantMessage(
              role: .tool,
              content:
                  'Not run: ${call.name} ended the turn to wait for the '
                  'person. Propose it again after their answer if it still '
                  'applies.',
              callId: other.id,
            ),
        ],
      ),
    );
    unawaited(_saveActive());
  }

  /// Previews, authorizes and executes a single call against the frozen turn.
  /// Cancellation is checked again after every asynchronous host boundary.
  ///
  /// Returns whether the tool ended the turn (`ToolOutcome.endsTurn`).
  Future<bool> _executeLocalCall(ToolCall call, String turn, int epoch) async {
    if (!_current(epoch)) {
      return false;
    }
    final executionKey = '$turn/${call.id}';
    final resolved = _registry!.resolve(call.name, call.arguments);
    final tool = resolved.when(ok: (tool) => tool, err: (_) => null);
    var outcome = switch (resolved.errorOrNull?.detail ?? '') {
      '' => 'Tool unavailable or invalid arguments.',
      final String detail => 'Tool unavailable or invalid arguments: $detail',
    };
    var failure = resolved.errorOrNull?.detail ?? '';
    var endsTurn = false;
    // Images the tool returned for the model to look at; they stay on the
    // result message and each transport sends them its own way.
    var images = const <AsystantAttachment>[];
    _step(
      executionKey,
      StepPhase.preparing,
      title: tool?.definition.description ?? call.name,
      toolName: call.name,
    );
    if (tool != null && !_executed.contains(executionKey)) {
      updateState(state.copyWith(phase: .executing));
      final preview = await tool.preview(call.arguments);
      if (!_current(epoch)) {
        return false;
      }
      final card = preview.when(ok: (card) => card, err: (_) => null);
      failure = preview.errorOrNull?.detail ?? '';
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
            return false;
          }
          _approval = null;
          updateState(state.copyWith(clearPending: true));
        }
        if (allowed && tool.isAvailable) {
          _step(executionKey, StepPhase.running, startedAt: DateTime.now());
          _executed.add(executionKey);
          updateState(state.copyWith(phase: .executing));
          final result = await tool.execute(
            call.arguments,
            ToolContext(
              idempotencyKey: executionKey,
              selectedOptions: List.unmodifiable(selected),
              attachments: state.conversationAttachments,
              isCanceled: () => !_current(epoch),
            ),
          );
          if (!_current(epoch)) {
            return false;
          }
          result.when(
            ok: (result) {
              _step(
                executionKey,
                StepPhase.completed,
                title: result.summary,
                data: result.data,
              );
              outcome = result.modelContent;
              endsTurn = result.endsTurn;
              images = List.unmodifiable(
                result.images.where((image) => image.isImage),
              );
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
            err: (error) {
              // The tool's reason reaches the model, so it can correct the
              // call instead of guessing.
              _step(executionKey, StepPhase.failed, detail: error.detail);
              outcome = switch (error.detail) {
                '' => 'Local tool failed. Do not assume it succeeded.',
                final String detail =>
                  'Local tool failed: $detail Do not assume it succeeded.',
              };
            },
          );
        } else {
          _step(executionKey, StepPhase.declined);
          outcome = 'User declined this action. Do not repeat it without a new request.';
        }
      } else {
        _step(executionKey, StepPhase.failed, detail: failure);
        outcome = 'Could not prepare a safe preview.';
      }
    }
    if (state.steps.any((step) => step.id == executionKey && step.active)) {
      _step(executionKey, StepPhase.failed, detail: failure);
    }
    updateState(
      state.copyWith(
        messages: [
          ...state.messages,
          AssistantMessage(
            role: .tool,
            content: outcome,
            callId: call.id,
            attachments: images,
          ),
        ],
      ),
    );
    return endsTurn;
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
