import 'package:result_controller/result_controller.dart';
import 'package:asystant_core/src/model/assistant_failure.dart';
import 'package:asystant_core/src/model/assistant_message.dart';
import 'package:asystant_core/src/model/system_prompt.dart';
import 'package:asystant_core/src/tool/tool_definition.dart';
import 'package:asystant_core/src/transport/inference_event.dart';

/// One transport per assistant instance; no global session or provider secrets.
abstract class AssistantTransport {
  /// The model assigned by the server after initialization.
  String? get defaultModel => null;

  /// Whether the user may select another permitted model.
  bool get allowModelSelection => true;

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
  Stream<InferenceEvent> infer({
    required List<AssistantMessage> messages,
    required String model,
    required String requestId,
  });

  /// Stops delivery for the current request without reversing completed effects.
  void cancel();

  /// Closes resources owned by this transport.
  Future<void> dispose();
}
