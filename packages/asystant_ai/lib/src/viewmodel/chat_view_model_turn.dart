part of 'chat_view_model.dart';

/// Turn of inference and streaming: sends a message, drives the
/// request/response rounds and keeps the step timeline up to date.
mixin _ChatTurn
    on
        ViewModel<ChatState>,
        _ChatLifecycle,
        _ChatConversations,
        _ChatComposition {
  static const _streamingInterval = Duration(milliseconds: 32);

  final StringBuffer _streamingText = StringBuffer();

  Timer? _streamingTimer;

  /// At most one progress update per interval reaches the state; see
  /// [_reportProgress].
  static const _progressInterval = Duration(milliseconds: 100);

  Timer? _progressTimer;

  /// The latest progress report not shown yet.
  ({String id, double fraction, String label})? _progress;

  /// When the last message went out; see [stop].
  DateTime? _sentAt;

  static const _stopGuard = Duration(milliseconds: 600);

  // ---------------------------------------------- bridge to sibling mixins
  // Declared here only so this mixin's methods can call/read members that
  // live in another mixin (or the concrete class); each is implemented
  // exactly once, in the mixin named in its doc comment.
  ChatState get state; // concrete in ChatViewModel
  Completer<bool>? get _approval; // concrete in _ChatTools
  set _approval(Completer<bool>? value); // concrete in _ChatTools
  Completer<Map<String, String>?>? get _privateInput; // concrete in _ChatTools
  set _privateInput(
    Completer<Map<String, String>?>? value,
  ); // concrete in _ChatTools
  List<AssistantMessage> _closePendingCalls(); // concrete in _ChatTools
  Future<bool> _executeLocalCall(
    ToolCall call,
    String turn,
    int epoch,
  ); // concrete in _ChatTools
  void _endTurnAt(
    ToolCall call, {
    required Iterable<ToolCall> skipped,
  }); // concrete in _ChatTools

  /// Stops the turn, except right after sending: a double tap on Send must
  /// not cancel the message it just sent.
  void stop() {
    final sentAt = _sentAt;
    if (sentAt != null && DateTime.now().difference(sentAt) < _stopGuard) {
      return;
    }
    cancel();
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
}
