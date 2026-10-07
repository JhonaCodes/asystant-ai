part of 'chat_view_model.dart';

/// Draft, model choice and attachments for the next message.
mixin _ChatComposition
    on ViewModel<ChatState>, _ChatLifecycle, _ChatConversations {
  // ---------------------------------------------- bridge to sibling mixins
  // Declared here only so this mixin's methods can call/read members that
  // live in another mixin (or the concrete class); each is implemented
  // exactly once, in the mixin named in its doc comment.
  ChatState get state; // concrete in ChatViewModel
  bool get canType; // concrete in ChatViewModel

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
}
