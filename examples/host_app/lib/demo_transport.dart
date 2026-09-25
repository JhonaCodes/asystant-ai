import 'package:asystant_ai/asystant_ai.dart';

/// Offline demonstration, explicitly labeled in the host app. No AI API is used.
class DemoTransport extends AssistantTransport {
  int _epoch = 0;
  @override
  bool get isAuthenticated => true;
  @override
  String? get identity => 'demo-local-session';
  @override
  Stream<void> get sessionChanges => const Stream.empty();
  @override
  Future<Result<List<String>, AssistantFailure>> initialize({
    required List<ToolDefinition> tools,
    required List<AsystantSystemPrompt> prompts,
    required List<String> models,
  }) async => Ok(['demo-local']);
  @override
  Stream<InferenceEvent> infer({
    required List<AssistantMessage> messages,
    required String model,
    required String requestId,
  }) async* {
    final epoch = _epoch;
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (epoch != _epoch) return;
    if (messages.last.role == MessageRole.user) {
      yield InferenceCompleted(
        AssistantMessage(
          role: .assistant,
          content: 'Preparé un borrador para tu espacio. Puedes revisar la acción antes de guardarlo.',
          calls: [
            ToolCall(
              id: requestId,
              name: 'create_draft',
              arguments: ToolArguments.fromJson({
                'title': messages.last.content,
              }),
            ),
          ],
        ),
      );
    } else {
      final done = messages.last.content == 'created';
      yield InferenceCompleted(
        AssistantMessage(
          role: .assistant,
          content: done
              ? 'El borrador está en tu app. Puedes cerrar el asistente y seguir trabajando.'
              : 'Entendido. No he guardado el borrador.',
        ),
      );
    }
  }

  @override
  void cancel() {
    _epoch++;
  }

  @override
  Future<void> dispose() async {
    cancel();
  }
}
