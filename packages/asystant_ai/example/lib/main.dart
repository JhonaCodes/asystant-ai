import 'package:flutter/material.dart';
import 'package:asystant_ai/asystant_ai.dart';

/// Reads application state without a network call or provider credential.
class ReadWorkspaceTool extends AsystantTool {
  const ReadWorkspaceTool();

  @override
  ToolDefinition get definition => const ToolDefinition(
    name: 'read_workspace',
    description: 'Read the name of the current workspace.',
    fields: [],
  );

  @override
  bool get requiresConfirmation => false;

  @override
  Future<Result<AssistantCard, AssistantFailure>> preview(
    ToolArguments arguments,
  ) async => Ok(const AssistantCard(title: 'Current workspace'));

  @override
  Future<Result<ToolOutcome, AssistantFailure>> execute(
    ToolArguments arguments,
    ToolContext context,
  ) async {
    context.checkCanceled();
    return Ok(const ToolOutcome(modelContent: 'Example workspace'));
  }
}

/// Demonstrates the protocol without making any inference API requests.
class ExampleTransport extends AssistantTransport {
  @override
  bool get isAuthenticated => true;
  @override
  String get identity => 'offline-example';
  @override
  Stream<void> get sessionChanges => const Stream.empty();
  @override
  Future<Result<List<String>, AssistantFailure>> initialize({
    required List<ToolDefinition> tools,
    required List<AsystantSystemPrompt> prompts,
    required List<String> models,
  }) async => Ok(['simulated-response']);
  @override
  Stream<InferenceEvent> infer({
    required List<AssistantMessage> messages,
    required String model,
    required String requestId,
  }) async* {
    yield InferenceCompleted(
      messages.last.role == .user
          ? AssistantMessage(
              role: .assistant,
              content: 'I will read the workspace using a local tool.',
              calls: [
                ToolCall(
                  id: requestId,
                  name: 'read_workspace',
                  arguments: ToolArguments.fromJson({}),
                ),
              ],
            )
          : const AssistantMessage(
              role: .assistant,
              content: 'The workspace is named Example workspace.',
            ),
    );
  }

  @override
  void cancel() {}
  @override
  Future<void> dispose() async {}
}

class ExampleAssistant extends AsystantAI {
  ExampleAssistant() : super(name: 'Assistant · offline demo');
  @override
  List<AsystantTool> get tools => const [ReadWorkspaceTool()];
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final assistant = ExampleAssistant();
  assistant.init(transport: ExampleTransport());
  runApp(ExampleApp(assistant: assistant));
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key, required this.assistant});
  final ExampleAssistant assistant;
  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  @override
  void dispose() {
    widget.assistant.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Local tools · simulated AI responses')),
      body: AsystantChat(
        assistant: widget.assistant,
        strings: const AsystantStrings(spanish: false),
      ),
    ),
  );
}
