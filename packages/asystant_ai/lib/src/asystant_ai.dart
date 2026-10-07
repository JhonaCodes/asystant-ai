import 'dart:async';
import 'dart:typed_data';

import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/model/asystant_model_option.dart';
import 'package:asystant_ai/src/model/asystant_action_policy.dart';
import 'package:asystant_ai/src/model/asystant_turn_limits.dart';
import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/presentation/asystant_presentation.dart';
import 'package:asystant_ai/src/presentation/asystant_presentation_registry.dart';
import 'package:asystant_ai/src/service/asystant_conversation_store.dart';
import 'package:asystant_ai/src/service/asystant_provider_settings.dart';
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

  /// Read-only presentations exposed as tools and restored as native widgets.
  List<AsystantPresentation> get presentations => const [];

  AsystantPresentationRegistry? _presentationRegistry;

  AsystantPresentationRegistry get presentationRegistry =>
      _presentationRegistry ??= AsystantPresentationRegistry(presentations);

  /// Product-specific instructions registered alongside tool schemas.
  List<AsystantSystemPrompt> get systemPrompts => const [];

  /// What the app knows right now, such as the person's saved profile.
  ///
  /// Read before every model call, so an answer already uses what a tool
  /// saved a moment before. Keep it short, since it travels with every
  /// request, and write it as data about the person rather than as rules:
  /// it can carry what the person said.
  Future<List<AsystantSystemPrompt>> contextPrompts() async => const [];

  /// Whether [tool] waits for the person's approval before this call runs.
  ///
  /// Asked on every call, after the tool's preview and before it runs, so a
  /// host can answer from settings that change while the chat is open, such
  /// as a switch that approves everything. By default it is the tool's own
  /// [AsystantTool.requiresConfirmation]. It never skips
  /// [AsystantTool.requiresSelection]: a choice is input, not a permission.
  bool requiresConfirmation(AsystantTool tool) => tool.requiresConfirmation;

  /// Classifies one validated tool call before it is shown or executed.
  ///
  /// A tool can implement [AsystantActionPolicyProvider] for an argument-aware
  /// policy. Override this method for a central host policy. Existing tools
  /// keep their [requiresConfirmation] behavior until classified explicitly.
  AsystantActionPolicy actionPolicyFor(
    AsystantTool tool,
    ToolArguments arguments,
  ) => switch (tool) {
    final AsystantActionPolicyProvider provider => provider.actionPolicy(
      arguments,
    ),
    _ => AsystantActionPolicy(requiresApproval: requiresConfirmation(tool)),
  };

  /// Whether tool registration and model assignment have completed.
  bool get isInitialized => conversation.notifier.isInitialized;

  /// Whether the configured transport has a valid host login.
  bool get isAuthenticated => conversation.notifier.isAuthenticated;

  Future<void> Function()? _initialize;

  Future<void>? _initialization;

  bool _disposed = false;

  AssistantTransport? _pendingTransport;

  AsystantProviderSettings? _providerSettings;

  /// Optional local provider and model settings, owned by this package.
  AsystantProviderSettings? get providerSettings => _providerSettings;

  /// Configures this instance once; create a new instance to replace its setup.
  /// Stores configuration without contacting the server or evaluating tools.
  ///
  /// [provider] says where answers come from: `OpenRouterProvider`,
  /// `ClaudeCodeProvider` or any other variant of [AsystantProvider]. Tools,
  /// prompts, context, attachments and the model picker work the same with
  /// all of them. [transport] is the advanced alternative for an
  /// [AssistantTransport] of your own, such as a test double or a proxy;
  /// pass exactly one of the two. The assistant owns the transport and
  /// disposes it with itself.
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
  /// [turnLimits] bounds each turn: inference rounds and tool calls per
  /// response (8 and 16 by default); an out-of-range value throws a
  /// [RangeError] here, before anything is stored.
  void init({
    AsystantProvider? provider,
    AssistantTransport? transport,
    List<AsystantModelOption> models = const [],
    List<AsystantTool> builtInTools = const [],
    List<AsystantSystemPrompt> additionalSystemPrompts = const [],
    AsystantConversationStore? conversationStore,
    AsystantAttachmentPolicy attachments = const AsystantAttachmentPolicy(),
    AsystantTurnLimits turnLimits = const AsystantTurnLimits(),
    AsystantProviderSettings? providerSettings,
    bool enableInlinePrivateInput = true,
  }) {
    if (_disposed || _initialize != null) {
      throw StateError('Configure the assistant before opening it.');
    }
    if ((provider == null) == (transport == null)) {
      throw ArgumentError('Pass exactly one of provider or transport.');
    }
    turnLimits.validate();
    if (providerSettings != null && provider == null) {
      throw ArgumentError('Local provider settings require a host provider.');
    }
    _providerSettings = providerSettings;
    _initialize = () async {
      final selection = await providerSettings?.load();
      final local = selection != null && selection.kind != .backend;
      final selected = local
          ? await providerSettings!.provider(selection)
          : provider;
      final configured = selected?.createTransport() ?? transport!;
      if (_disposed) {
        await configured.dispose();
        return;
      }
      _pendingTransport = configured;
      final registeredTools = [
        ...builtInTools,
        ...tools,
        ...presentationRegistry.tools,
      ];
      final registeredPrompts = [...systemPrompts, ...additionalSystemPrompts];
      await conversation.notifier.configure(
        transport: configured,
        tools: registeredTools,
        prompts: registeredPrompts,
        models: local
            ? [AsystantModelOption.fallback(selection.model.trim())]
            : models,
        preferredModel: selection?.model,
        store: conversationStore,
        attachmentPolicy: attachments,
        context: contextPrompts,
        turnLimits: turnLimits,
        confirmation: requiresConfirmation,
        actionPolicy: actionPolicyFor,
        enableInlinePrivateInput: enableInlinePrivateInput,
      );
      _pendingTransport = null;
    };
  }

  /// Applies a changed local provider/model without losing saved conversations.
  /// The settings UI calls this only while no turn is running.
  Future<void> refreshProvider() async {
    if (_disposed ||
        _initialization != null ||
        conversation.notifier.state.busy ||
        conversation.notifier.state.phase == ChatPhase.initializing) {
      throw StateError('Finish the current request before changing provider.');
    }
    await _initialize?.call();
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
