import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/model/assistant_failure.dart';
import 'package:asystant_core/src/model/assistant_message.dart';
import 'package:asystant_core/src/model/asystant_model_catalog.dart';
import 'package:asystant_core/src/model/asystant_provider_status.dart';
import 'package:asystant_core/src/model/system_prompt.dart';
import 'package:asystant_core/src/tool/tool_definition.dart';
import 'package:asystant_core/src/transport/inference_event.dart';

/// One transport per assistant instance; no global session or provider secrets.
///
/// Everything above a transport (tools, prompts, per-request context,
/// attachments, the model picker, permissions and cards) only uses this
/// contract, so it works the same with every provider. A provider adds its
/// own transport; see `AsystantProvider`.
abstract class AssistantTransport {
  /// The model assigned by the server after initialization.
  String? get defaultModel => null;

  /// Whether the user may select another permitted model.
  bool get allowModelSelection => true;

  /// The context window of [model] in tokens, when the provider reports it.
  int? contextLengthOf(String model) => null;

  /// Whether the transport is currently bound to a valid host login.
  bool get isAuthenticated;

  /// Stable host login identity; null indicates a signed-out session.
  String? get identity;

  /// Notifies consumers when the host authentication context changes.
  Stream<void> get sessionChanges;

  /// Registers schemas and returns the models permitted by the server.
  Future<Result<List<String>, AssistantFailure>> initialize({
    required List<ToolDefinition> tools,
    required List<AsystantSystemPrompt> prompts,
    required List<String> models,
  });

  /// Requests one inference with a unique request ID; never executes local tools.
  ///
  /// [context] is what the host knows right now, such as the person's saved
  /// profile. It goes after the configured prompts, for this request only.
  Stream<InferenceEvent> infer({
    required List<AssistantMessage> messages,
    required String model,
    required String requestId,
    List<AsystantSystemPrompt> context = const [],
  });

  /// Checks that the provider can answer, without running an inference: a
  /// local program is installed and signed in, or a key is accepted.
  ///
  /// `Err` when it cannot be reached at all. The default reports that this
  /// transport has no such check.
  Future<Result<AsystantProviderStatus, AssistantFailure>> verify() async =>
      Err(
        const AssistantFailure(
          .unavailable,
          detail: 'This transport cannot verify its connection.',
        ),
      );

  /// The models and effort levels the provider offers, for a model picker.
  ///
  /// `Err` when they cannot be read. The default reports that this
  /// transport publishes no catalog.
  Future<Result<AsystantModelCatalog, AssistantFailure>> modelCatalog() async =>
      Err(
        const AssistantFailure(
          .unavailable,
          detail: 'This transport does not publish a model catalog.',
        ),
      );

  /// Stops delivery for the current request without reversing completed effects.
  void cancel();

  /// Closes resources owned by this transport.
  Future<void> dispose();
}
