part of 'chat_view_model.dart';

/// Local tools and approvals: previews, authorizes and executes each call
/// the model asks for, and resolves private-input and permission waits.
mixin _ChatTools
    on
        ViewModel<ChatState>,
        _ChatLifecycle,
        _ChatConversations,
        _ChatComposition,
        _ChatTurn {
  Completer<bool>? _approval;
  Completer<Map<String, String>?>? _privateInput;

  // ---------------------------------------------- bridge to sibling mixins
  // Declared here only so this mixin's methods can call/read members that
  // live in another mixin (or the concrete class); each is implemented
  // exactly once, in the mixin named in its doc comment.
  ChatState get state; // concrete in ChatViewModel
  AsystantStrings get _strings; // concrete in ChatViewModel

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
}
