import 'dart:async';

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
import 'package:asystant_ai/src/service/random_hex_id.dart';

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

// keel-debt: about 1340 lines in one class, because every part shares the same
//   private state. Shrinking it means redesigning the turn flow, in a major.
/// Owns conversation state and executes only registered, authorized local tools.
class ChatViewModel extends ViewModel<ChatState> {
  ChatViewModel() : super(const ChatState());

  static const _streamingInterval = Duration(milliseconds: 32);

  AssistantTransport? _transport;

  ToolRegistry? _registry;

  StreamSubscription<void>? _session;

  AsystantConversationStore _store = InMemoryConversationStore();

  Completer<bool>? _approval;
  Completer<Map<String, String>?>? _privateInput;
  bool _enableInlinePrivateInput = true;
  AsystantStrings _strings = AsystantStrings.english;

  /// The current host text bundle for labels created while a tool runs.
  void setStrings(AsystantStrings strings) => _strings = strings;

  int _epoch = 0;

  bool _closed = false;

  bool _initialized = false;

  String? _identity;

  String? _preferredModel;

  final Set<String> _executed = {};
  final ChatSecretVault _secrets = ChatSecretVault();

  final StringBuffer _streamingText = StringBuffer();

  Timer? _streamingTimer;

  /// At most one progress update per interval reaches the state; see
  /// [_reportProgress].
  static const _progressInterval = Duration(milliseconds: 100);

  Timer? _progressTimer;

  /// The latest progress report not shown yet.
  ({String id, double fraction, String label})? _progress;

  AsystantAttachmentPolicy _attachmentPolicy = const AsystantAttachmentPolicy();

  /// Rounds per turn and calls per response; see [AsystantTurnLimits].
  AsystantTurnLimits _turnLimits = const AsystantTurnLimits();

  /// What the host knows now; read again before every model call.
  AsystantContextSource _context = _noContext;

  static Future<List<AsystantSystemPrompt>> _noContext() async => const [];

  /// Whether a call waits for the person; asked again on every call.
  AsystantConfirmationPolicy _confirmation = _toolDecides;

  AsystantActionPolicyResolver? _actionPolicy;

  bool _approvesAllForSession = false;

  static bool _toolDecides(AsystantTool tool) => tool.requiresConfirmation;

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
  bool get canType =>
      _initialized && state.pending == null && state.privateInput == null;

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
    String? preferredModel,
    AsystantConversationStore? store,
    AsystantAttachmentPolicy attachmentPolicy =
        const AsystantAttachmentPolicy(),
    AsystantContextSource? context,
    AsystantTurnLimits turnLimits = const AsystantTurnLimits(),
    AsystantConfirmationPolicy? confirmation,
    AsystantActionPolicyResolver? actionPolicy,
    bool enableInlinePrivateInput = true,
  }) async {
    turnLimits.validate();
    if (_closed || state.isBusyOrInitializing) {
      return;
    }
    if (_initialized) await _saveActive();
    if (_closed || state.busy) return;
    final epoch = ++_epoch;
    _initialized = false;
    final previousTransport = _transport;
    _transport = transport;
    if (store != null) {
      _store = store;
    }
    _attachmentPolicy = attachmentPolicy;
    _turnLimits = turnLimits;
    _preferredModel = preferredModel;
    _context = context ?? _noContext;
    _confirmation = confirmation ?? _toolDecides;
    _actionPolicy = actionPolicy;
    _enableInlinePrivateInput = enableInlinePrivateInput;
    _approvesAllForSession = false;
    // A retry for the same person keeps the conversations; anyone else
    // starts clean.
    final sameIdentity = _identity != null && _identity == transport.identity;
    if (!sameIdentity) _secrets.clear();
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
        _identity = transport.identity;
        _executed.clear();
        _secrets.clear();
        _approvesAllForSession = false;
        updateState(ChatState(phase: ChatPhase.idle, conversationId: _newId()));
      }
    });
    final validation = _registry!.validate();
    if (validation.isErr) {
      _fail(validation.errorOrNull!);
      return;
    }
    final promptPolicy = const AsystantPromptPolicy().compose([
      ...prompts,
      const AsystantSystemPrompt(
        id: 'asystant-private-values',
        content:
            'A [secret:...] reference in a user message stands for a '
            'private value. Never ask to reveal or repeat it. When a local '
            'tool needs that value, pass the reference exactly as the whole '
            'argument value. The app resolves it only after preview and '
            'approval. When you need a new private value, ask the user to '
            'attach it with the key icon beside file attachment if that icon '
            'is available, or to prefix the value with \$ in the chat. Both '
            'methods send only a reference to you. Do not ask for an '
            'unmarked raw value. An expired reference requires the user to '
            'provide it again.',
      ),
    ]);
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
                  : allowed.contains(preferredModel)
                  ? preferredModel
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
    final summaries = saved.when(ok: (items) => items, err: (_) => null);
    if (summaries == null) return;
    final ordered = {
      for (final summary in [...summaries, ...state.conversations])
        summary.id: summary,
    }.values.sorted((a, b) => b.updatedAt.compareTo(a.updatedAt));
    updateState(state.copyWith(conversations: ordered));
    final active = await _store.activeId(_scope);
    if (!_current(epoch)) return;
    final id = active.when(ok: (value) => value, err: (_) => null);
    if (id != null && ordered.every((summary) => summary.id != id)) {
      _showConversation(id: id);
      return;
    }
    final restoreId = id ?? ordered.firstOrNull?.id;
    if (restoreId == null) return;
    final snapshot = await _store.read(_scope, restoreId);
    if (!_current(epoch)) return;
    snapshot.when(
      ok: (saved) => _showConversation(
        id: saved.summary.id,
        messages: saved.messages,
        entries: saved.entries,
        model: saved.summary.model,
        usage: saved.summary.usage,
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

  /// Returns an opaque reference for the composer to insert at the cursor.
  /// The raw value stays only in the in-memory vault until local execution.
  String? reserveSecret(String value) {
    if (!canType || value.trim().isEmpty) return null;
    return _secrets.reserve(state.conversationId, value);
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
    final issue = (policy ?? _attachmentPolicy).issueForAttachment(
      file,
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
    var issue = picked.issue;
    for (final file in picked.files) {
      final fileIssue = attach(file, policy: rules);
      issue ??= fileIssue;
    }
    if (issue != null) rejectAttachment(issue);
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

  /// Keeps the conversation on screen in the store, then reads the list again
  /// and replaces the one shown with exactly what the store answers.
  ///
  /// For hosts whose store answers per context of their own (one list per
  /// open document, say): after switching the context, call this, then
  /// [openConversation] or [newConversation]. The conversation on screen
  /// stays until then.
  Future<void> reloadConversations() async {
    if (!canManageConversations) {
      return;
    }
    await _saveActive();
    final epoch = _epoch;
    final saved = await _store.list(_scope);
    if (!_current(epoch) || !canManageConversations) {
      return;
    }
    saved.when(
      ok: (summaries) => updateState(
        state.copyWith(
          conversations: summaries.sorted(
            (a, b) => b.updatedAt.compareTo(a.updatedAt),
          ),
        ),
      ),
      err: (_) {},
    );
  }

  /// Deletes [id]; deleting the one on screen also clears it.
  Future<void> deleteConversation(String id) async {
    if (!canManageConversations) {
      return;
    }
    await _store.delete(_scope, id);
    _secrets.forget(id);
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
    if (_initialized) {
      unawaited(_store.setActiveId(_scope, id));
    }
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
            : state.models.contains(_preferredModel)
            ? _preferredModel
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

  String _newId() => randomHexId(16);

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

  /// Approves this action and later eligible approvals in this login only.
  void approveAllForSession() {
    final pending = state.pending;
    if (pending == null ||
        !pending.canApprove ||
        !pending.policy.requiresApproval ||
        !pending.policy.allowSessionApproval) {
      return;
    }
    _approvesAllForSession = true;
    approve(true);
  }

  void submitPrivateInput(Map<String, String> values) {
    final request = state.privateInput;
    if (request == null || _privateInput?.isCompleted != false) return;
    if (values.keys
        .toSet()
        .difference(request.fields.map((f) => f.name).toSet())
        .isNotEmpty)
      return;
    for (final field in request.fields) {
      if (field.required && (values[field.name]?.trim().isEmpty ?? true))
        return;
    }
    _privateInput!.complete(Map.unmodifiable(values));
  }

  void declinePrivateInput() {
    if (_privateInput?.isCompleted == false) _privateInput!.complete(null);
  }

  Future<Map<String, String>?> _requestPrivateInput(
    int epoch,
    String title,
    List<PrivateInputField> fields,
  ) async {
    if (!_current(epoch) || fields.isEmpty || _privateInput != null)
      return null;
    final names = fields.map((field) => field.name).toSet();
    if (names.length != fields.length ||
        fields.any((field) => field.name.isEmpty))
      return null;
    final waiter = Completer<Map<String, String>?>();
    _privateInput = waiter;
    updateState(
      state.copyWith(
        phase: .permission,
        privateInput: PrivateInputRequest(
          id: _newId(),
          title: title,
          fields: List.unmodifiable(fields),
        ),
      ),
    );
    final result = await waiter.future;
    if (identical(_privateInput, waiter)) _privateInput = null;
    if (_current(epoch))
      updateState(state.copyWith(phase: .executing, clearPrivateInput: true));
    return _current(epoch) ? result : null;
  }

  void cancel() {
    _epoch++;
    _resetStreaming();
    _resetProgress();
    _transport?.cancel();
    if (_approval?.isCompleted == false) {
      _approval?.complete(false);
    }
    _approval = null;
    if (_privateInput?.isCompleted == false) _privateInput?.complete(null);
    _privateInput = null;
    if (!_closed) {
      updateState(
        state.copyWith(
          phase: .canceled,
          entries: _archivedActivity(_endSteps(StepPhase.canceled)),
          steps: const [],
          messages: _closePendingCalls(),
          streaming: '',
          clearPending: true,
          clearPrivateInput: true,
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
    _resetProgress();
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
    double? progress,
    String? progressLabel,
    List<AsystantAttachment>? images,
    AsystantSensitivity? sensitivity,
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
                            progress: progress,
                            progressLabel: progressLabel,
                            images: images,
                            sensitivity: sensitivity,
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
                  progress: progress,
                  progressLabel: progressLabel ?? '',
                  images: images ?? const [],
                  sensitivity: sensitivity,
                ),
              ],
      ),
    );
  }

  Future<void> send([String? text]) async {
    final rawContent = (text ?? state.draft).trim();
    final files = state.attachments;
    if (!_initialized ||
        state.busy ||
        (rawContent.isEmpty && files.isEmpty) ||
        _transport == null) {
      return;
    }
    final content = _secrets.protect(state.conversationId, rawContent);
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
    unawaited(_saveActive());
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

  /// Shows a running tool's progress on its step without rebuilding the
  /// chat on every report: the first report shows at once, and then at most
  /// one per [_progressInterval], always the latest.
  void _reportProgress(String id, int epoch, double fraction, String label) {
    if (!_current(epoch)) {
      return;
    }
    _progress = (id: id, fraction: fraction, label: label);
    if (_progressTimer == null) {
      _flushProgress(epoch);
    }
  }

  void _flushProgress(int epoch) {
    final progress = _progress;
    _progress = null;
    if (progress == null || !_current(epoch)) {
      return;
    }
    _progressTimer = Timer(_progressInterval, () {
      _progressTimer = null;
      _flushProgress(epoch);
    });
    // Only the call still running shows it: a late report must not revive
    // a step that already ended.
    if (state.steps.any(
      (step) => step.id == progress.id && step.phase == StepPhase.running,
    )) {
      _step(
        progress.id,
        StepPhase.running,
        progress: progress.fraction,
        progressLabel: progress.label,
      );
    }
  }

  void _resetProgress() {
    _progressTimer?.cancel();
    _progressTimer = null;
    _progress = null;
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
    final usesSecret = _secrets.containsReference(call.arguments);
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
        final policy =
            _actionPolicy?.call(tool, call.arguments) ??
            AsystantActionPolicy(requiresApproval: _confirmation(tool));
        _step(
          executionKey,
          StepPhase.preparing,
          title: card.title,
          sensitivity: policy.displaySensitivity,
        );
        // A choice is input the tool needs, not a permission, so the policy
        // never skips it.
        final needsApproval =
            policy.requiresApproval &&
            !(_approvesAllForSession && policy.allowSessionApproval);
        var allowed = !needsApproval && !tool.requiresSelection;
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
                policy: policy,
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
        final executionArguments = allowed && tool.isAvailable
            ? _secrets.resolve(
                state.conversationId,
                call.arguments,
                tool.definition.fields,
              )
            : null;
        if (allowed && tool.isAvailable && executionArguments == null) {
          _step(
            executionKey,
            StepPhase.failed,
            detail: _strings.secretReferenceExpired,
          );
          outcome = 'Secret reference expired. Ask the user to send it again.';
        } else if (allowed && tool.isAvailable) {
          _step(executionKey, StepPhase.running, startedAt: DateTime.now());
          _executed.add(executionKey);
          updateState(state.copyWith(phase: .executing));
          var usedPrivateInput = false;
          final result = await tool.execute(
            executionArguments!,
            ToolContext(
              idempotencyKey: executionKey,
              selectedOptions: List.unmodifiable(selected),
              attachments: state.conversationAttachments,
              isCanceled: () => !_current(epoch),
              onPrivateInput: _enableInlinePrivateInput
                  ? (title, fields) async {
                      usedPrivateInput = true;
                      return _requestPrivateInput(epoch, title, fields);
                    }
                  : null,
              onProgress: (fraction, label) => _reportProgress(
                executionKey,
                epoch,
                fraction,
                usesSecret || usedPrivateInput
                    ? 'Ejecutando con un valor privado'
                    : _secrets.redact(state.conversationId, label),
              ),
            ),
          );
          if (!_current(epoch)) {
            return false;
          }
          // What the tool reported last is not shown after it returns.
          _resetProgress();
          result.when(
            ok: (result) {
              if (usesSecret || usedPrivateInput) {
                _step(
                  executionKey,
                  StepPhase.completed,
                  title: _strings.privateActionCompleted,
                );
                outcome =
                    'Local tool completed successfully with a private '
                    'value. The value and tool output are withheld.';
                endsTurn = result.endsTurn;
                return;
              }
              images = List.unmodifiable(
                result.images.where((image) => image.isImage),
              );
              // The step shows the images to the person; the result message
              // below carries the same ones to the model.
              _step(
                executionKey,
                StepPhase.completed,
                title: result.summary == null
                    ? null
                    : _secrets.redact(state.conversationId, result.summary!),
                data: (_secrets.redactValue(
                  state.conversationId,
                  result.data,
                ) as Map).cast<String, Object?>(),
                images: images,
              );
              outcome = _secrets.redact(
                state.conversationId,
                result.modelContent,
              );
              endsTurn = result.endsTurn;
              if (result.card case final card?) {
                final safeCard = AssistantCard.fromJson(
                  (_secrets.redactValue(
                    state.conversationId,
                    card.toJson(),
                  ) as Map).cast<String, Object?>(),
                );
                updateState(
                  state.copyWith(
                    cards: [...state.cards, safeCard],
                    entries: [
                      ...state.entries,
                      ChatEntry(card: safeCard),
                    ],
                  ),
                );
              }
            },
            err: (error) {
              if (usesSecret || usedPrivateInput) {
                _step(
                  executionKey,
                  StepPhase.failed,
                  detail: _strings.privateActionFailed,
                );
                outcome =
                    'Local tool failed while using a private value. '
                    'Do not assume it succeeded.';
                return;
              }
              // The tool's reason reaches the model, so it can correct the
              // call instead of guessing.
              final safeDetail = _secrets.redact(
                state.conversationId,
                error.detail,
              );
              _step(executionKey, StepPhase.failed, detail: safeDetail);
              outcome = switch (safeDetail) {
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
    _secrets.clear();
    _closed = true;
    unawaited(_session?.cancel());
    unawaited(_transport?.dispose());
    super.dispose();
  }
}
