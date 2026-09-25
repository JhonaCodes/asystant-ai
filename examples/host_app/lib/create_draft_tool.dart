import 'package:asystant_ai/asystant_ai.dart';

import 'workspace_service.dart';

class CreateDraftTool extends AsystantTool {
  const CreateDraftTool();
  @override
  ToolDefinition get definition => const ToolDefinition(
    name: 'create_draft',
    description:
        'Create a draft in the current workspace after the user approves.',
    fields: [
      ToolField(
        name: 'title',
        description: 'Draft title',
        kind: ToolFieldKind.string,
      ),
    ],
  );
  @override
  Future<Result<AssistantCard, AssistantFailure>> preview(
    ToolArguments arguments,
  ) async => Ok(
    AssistantCard(
      title: 'Guardar borrador',
      body: arguments.string('title'),
      kind: AssistantCardKind.permission,
    ),
  );
  @override
  Future<Result<ToolOutcome, AssistantFailure>> execute(
    ToolArguments arguments,
    ToolContext context,
  ) async {
    context.checkCanceled();
    WorkspaceService.drafts.notifier.create(
      arguments.string('title'),
      context.idempotencyKey,
    );
    return Ok(
      ToolOutcome(
        modelContent: 'created',
        card: AssistantCard(
          title: 'Borrador guardado',
          body: arguments.string('title'),
          kind: AssistantCardKind.result,
        ),
      ),
    );
  }
}
