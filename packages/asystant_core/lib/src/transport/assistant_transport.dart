import 'package:result_controller/result_controller.dart';
import 'package:asystant_core/src/model/assistant_failure.dart';
import 'package:asystant_core/src/model/assistant_message.dart';
import 'package:asystant_core/src/model/system_prompt.dart';
import 'package:asystant_core/src/tool/tool_definition.dart';
import 'package:asystant_core/src/transport/inference_event.dart';

/// One transport per assistant instance; no global session or provider secrets.
abstract class AssistantTransport {
  String? get defaultModel => null;
  bool get allowModelSelection => true;
  bool get isAuthenticated;
  String? get identity;
  Stream<void> get sessionChanges;
  Future<Result<List<String>, AssistantFailure>> initialize({
    required List<ToolDefinition> tools,
    required List<AsystantSystemPrompt> prompts,
    required List<String> models,
  });
  Stream<InferenceEvent> infer({
    required List<AssistantMessage> messages,
    required String model,
    required String requestId,
  });
  void cancel();
  Future<void> dispose();
}
