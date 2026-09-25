import 'package:asystant_core/asystant_core.dart';

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

Future<void> main() async {
  const tool = ReadWorkspaceTool();
  final outcome = await tool.execute(
    ToolArguments.fromJson({}),
    ToolContext(
      idempotencyKey: 'local-read-example',
      selectedOptions: const [],
      isCanceled: () => false,
    ),
  );
  outcome.when(
    ok: (completed) => print(completed.modelContent),
    err: (failure) => print('Tool failed: ${failure.code.name}'),
  );
}
