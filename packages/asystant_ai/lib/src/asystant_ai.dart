import 'dart:async';
import 'dart:typed_data';

import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/model/asystant_model_option.dart';
import 'package:asystant_ai/src/service/asystant_conversation_store.dart';
import 'package:asystant_ai/src/service/asystant_service.dart';

/// Extend in the host application; register local tools after host authentication.
abstract class AsystantAI with AsystantService {
  AsystantAI({this.name = 'Assistant', this.description});

  /// Visible assistant name chosen by the host app.
  final String name;

  /// A fixed line under the name, such as "PortPlay assistant"; the chat
  /// shows its live status there when null.
  final String? description;

  /// Local application tools to register during initialization.
  List<AsystantTool> get tools;

  /// Product-specific instructions registered alongside tool schemas.
  List<AsystantSystemPrompt> get systemPrompts => const [];

  /// What the app knows right now, such as the person's saved profile.
  ///
  /// Read before every model call, so an answer already uses what a tool
  /// saved a moment before. Keep it short, since it travels with every
  /// request, and write it as data about the person rather than as rules:
  /// it can carry what the person said.
  Future<List<AsystantSystemPrompt>> contextPrompts() async => const [];

  /// Whether tool registration and model assignment have completed.
  bool get isInitialized => conversation.notifier.isInitialized;

  /// Whether the configured transport has a valid host login.
  bool get isAuthenticated => conversation.notifier.isAuthenticated;

  Future<void> Function()? _initialize;

  Future<void>? _initialization;

  bool _disposed = false;

  AssistantTransport? _pendingTransport;

  /// Configures this instance once; create a new instance to replace its setup.
  /// Stores configuration without contacting the server or evaluating tools.
  ///
  /// The chat starts initialization after its first frame. Applications without
  /// the built-in chat can call [ensureInitialized] when opening their UI.
  /// An empty model list accepts server policy. Additional prompts supplement
  /// [systemPrompts] and the built-in security instructions.
  /// [conversationStore] keeps the conversations that are not on screen;
  /// by default they live in memory until the app closes. [attachments]
  /// limits the files people can attach (every type by default); a chat
  /// widget can override it. [models] are the levels the person can choose
  /// next to the send button, each with the provider's id, a name and an
  /// optional icon and description; the first allowed one is the default.
  void init({
    required AssistantTransport transport,
    List<AsystantModelOption> models = const [],
    List<AsystantTool> builtInTools = const [],
    List<AsystantSystemPrompt> additionalSystemPrompts = const [],
    AsystantConversationStore? conversationStore,
    AsystantAttachmentPolicy attachments = const AsystantAttachmentPolicy(),
  }) {
    if (_disposed || _initialize != null) {
      throw StateError('Configure the assistant before opening it.');
    }
    _pendingTransport = transport;
    _initialize = () {
      final registeredTools = [...builtInTools, ...tools];
      final registeredPrompts = [...systemPrompts, ...additionalSystemPrompts];
      _pendingTransport = null;
      return conversation.notifier.configure(
        transport: transport,
        tools: registeredTools,
        prompts: registeredPrompts,
        models: models,
        store: conversationStore,
        attachmentPolicy: attachments,
        context: contextPrompts,
      );
    };
  }

  /// Starts deferred setup once; concurrent callers share the same operation.
  ///
  /// Network failures are represented by the chat state. Reopening a failed or
  /// expired session retries initialization, without replaying any user action.
  Future<void> ensureInitialized() {
    if (_disposed) {
      return Future.value();
    }
    final initialize = _initialize;
    if (initialize == null) {
      return Future.value();
    }
    if (isInitialized) {
      return Future.value();
    }
    return _initialization ??=
        Future<void>(() async {
          if (!_disposed) {
            try {
              await initialize();
            } catch (_) {
              if (!_disposed) {
                conversation.notifier.reportInitializationFailure();
              }
            }
          }
        }).whenComplete(() {
          _initialization = null;
        });
  }

  /// Adds a file to the next message from code, e.g. a photo the app just
  /// took. Returns why it was refused, or null when it was attached.
  AttachmentIssue? attachFile({
    required Uint8List bytes,
    required String filename,
    String? mimeType,
  }) => conversation.notifier.attach(
    AsystantAttachment.fromBytes(
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    ),
  );

  /// Sends [text] (with any attached files) from code, connecting first
  /// when needed. The answer appears in the chat like any other.
  Future<void> sendMessage(String text) async {
    await ensureInitialized();
    await conversation.notifier.send(text);
  }

  /// Releases this instance and invalidates pending local actions.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    unawaited(_pendingTransport?.dispose());
    _pendingTransport = null;
    _initialize = null;
    disposeConversation();
  }
}
