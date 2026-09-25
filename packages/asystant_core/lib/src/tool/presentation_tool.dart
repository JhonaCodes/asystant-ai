import 'package:result_controller/result_controller.dart';

import '../model/assistant_card.dart';
import '../model/assistant_failure.dart';
import 'asystant_tool.dart';
import 'tool_arguments.dart';
import 'tool_context.dart';
import 'tool_definition.dart';
import 'tool_field.dart';
import 'tool_outcome.dart';

/// Optional built-in UI tool. It never writes to application data.
class PresentationTool extends AsystantTool {
  const PresentationTool({this.kind = AssistantCardKind.summary});
  final AssistantCardKind kind;
  @override
  bool get requiresConfirmation => kind == AssistantCardKind.permission;
  @override
  bool get requiresSelection => kind == AssistantCardKind.selection;
  @override
  ToolDefinition get definition => ToolDefinition(
    name: 'present_${kind.name}',
    description:
        'Present a ${kind.name} card to the user. This does not change application data.',
    fields: const [
      ToolField(
        name: 'title',
        description: 'Card title',
        kind: ToolFieldKind.string,
      ),
      ToolField(
        name: 'body',
        description: 'Card description',
        kind: ToolFieldKind.string,
      ),
      ToolField(
        name: 'options',
        description: 'Choices for selection cards',
        kind: ToolFieldKind.strings,
        isRequired: false,
      ),
    ],
  );
  AssistantCard _card(ToolArguments arguments) => AssistantCard(
    title: arguments.string('title'),
    body: arguments.string('body'),
    kind: kind,
    options: arguments.strings('options'),
  );
  @override
  Future<Result<AssistantCard, AssistantFailure>> preview(
    ToolArguments arguments,
  ) async => Ok(_card(arguments));
  @override
  Future<Result<ToolOutcome, AssistantFailure>> execute(
    ToolArguments arguments,
    ToolContext context,
  ) async => Ok(
    ToolOutcome(
      modelContent: requiresSelection
          ? 'Selected: ${context.selectedOptions.join(', ')}'
          : 'Card shown.',
      card: requiresSelection
          ? _card(arguments).copyWith(
              kind: .result,
              body: context.selectedOptions.join('\n'),
              options: const [],
            )
          : _card(arguments),
    ),
  );
}
