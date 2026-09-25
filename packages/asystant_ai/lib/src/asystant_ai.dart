import 'dart:async';

import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/service/asystant_service.dart';

/// Extend in the host application; register local tools after host authentication.
abstract class AsystantAI with AsystantService {
  AsystantAI({this.name = 'Assistant'});

  /// Visible assistant name chosen by the host app.
  final String name;

  /// Local application tools to register during initialization.
  List<AsystantTool> get tools;

  /// Product-specific instructions registered alongside tool schemas.
  List<AsystantSystemPrompt> get systemPrompts => const [];

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
  void init({
    required AssistantTransport transport,
    List<String> models = const [],
    List<AsystantTool> builtInTools = const [],
    List<AsystantSystemPrompt> additionalSystemPrompts = const [],
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
