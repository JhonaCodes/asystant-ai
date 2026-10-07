part of 'chat_view_model.dart';

/// Configuration and lifecycle: wires the transport, tools and prompts on
/// [ChatViewModel.configure], and tears everything down on dispose.
mixin _ChatLifecycle on ViewModel<ChatState> {
  AssistantTransport? _transport;

  ToolRegistry? _registry;

  StreamSubscription<void>? _session;

  AsystantConversationStore _store = InMemoryConversationStore();

  bool _enableInlinePrivateInput = true;

  int _epoch = 0;

  bool _closed = false;

  bool _initialized = false;

  String? _identity;

  String? _preferredModel;

  final Set<String> _executed = {};
  final ChatSecretVault _secrets = ChatSecretVault();

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

  // ---------------------------------------------- bridge to sibling mixins
  // Declared here only so this mixin's methods can call/read members that
  // live in another mixin (or the concrete class); each is implemented
  // exactly once, in the mixin named in its doc comment.
  ChatState get state; // concrete in ChatViewModel
  String get _scope; // concrete in ChatViewModel
  Future<void> _saveActive(); // concrete in _ChatConversations
  String _newId(); // concrete in _ChatConversations
  void _showConversation({
    required String id,
    List<AssistantMessage> messages,
    List<ChatEntry> entries,
    String? model,
    TokenUsage? usage,
  }); // concrete in _ChatConversations
  void cancel(); // concrete in _ChatTurn
  void _fail(AssistantFailure failure); // concrete in _ChatTurn

  @override
  void init() {}

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
    if (_closed || state.busy || state.phase == ChatPhase.initializing) {
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
