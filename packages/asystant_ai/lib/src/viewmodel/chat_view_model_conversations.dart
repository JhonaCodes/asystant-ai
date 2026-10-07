part of 'chat_view_model.dart';

/// Conversations and persistence: listing, opening, reloading and deleting
/// against the configured [AsystantConversationStore].
mixin _ChatConversations on ViewModel<ChatState>, _ChatLifecycle {
  // ---------------------------------------------- bridge to sibling mixins
  // Declared here only so this mixin's methods can call/read members that
  // live in another mixin (or the concrete class); each is implemented
  // exactly once, in the mixin named in its doc comment.
  ChatState get state; // concrete in ChatViewModel
  bool get canManageConversations; // concrete in ChatViewModel
  String get _scope; // concrete in ChatViewModel
  void _resetStreaming(); // concrete in _ChatTurn

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

  String _newId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
