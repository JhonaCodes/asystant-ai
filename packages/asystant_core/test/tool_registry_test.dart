import 'package:asystant_core/src/model/assistant_card.dart';
import 'package:asystant_core/src/model/assistant_failure.dart';
import 'package:asystant_core/src/tool/asystant_tool.dart';
import 'package:asystant_core/src/tool/tool_arguments.dart';
import 'package:asystant_core/src/tool/tool_context.dart';
import 'package:asystant_core/src/tool/tool_definition.dart';
import 'package:asystant_core/src/tool/tool_field.dart';
import 'package:asystant_core/src/tool/tool_outcome.dart';
import 'package:asystant_core/src/tool/tool_registry.dart';
import 'package:result_controller/result_controller.dart';
import 'package:test/test.dart';

class ExampleTool extends AsystantTool {
  const ExampleTool();
  @override
  ToolDefinition get definition => const ToolDefinition(
    name: 'host_create',
    description: 'Create draft',
    fields: [ToolField(name: 'title', description: 'Title', kind: .string)],
  );
  @override
  Future<Result<AssistantCard, AssistantFailure>> preview(
    ToolArguments arguments,
  ) async => Ok(AssistantCard(title: arguments.string('title')));
  @override
  Future<Result<ToolOutcome, AssistantFailure>> execute(
    ToolArguments arguments,
    ToolContext context,
  ) async => Ok(ToolOutcome(modelContent: 'created'));
}

void main() {
  test('duplicate registrations fail before initialization', () {
    expect(
      ToolRegistry([const ExampleTool(), const ExampleTool()]).validate().isErr,
      isTrue,
    );
  });
  test('valid call resolves the local tool', () {
    expect(
      ToolRegistry([const ExampleTool()])
          .resolve('host_create', const ToolArguments('{"title":"Water"}'))
          .isOk,
      isTrue,
    );
  });
  test('unknown, missing, extra and malformed arguments cannot execute', () {
    final registry = ToolRegistry([const ExampleTool()]);
    for (final input in [
      '{}',
      '{"title":3}',
      '{"title":"ok","extra":true}',
      'invalid',
    ]) {
      expect(
        registry.resolve('host_create', ToolArguments(input)).isErr,
        isTrue,
      );
    }
    expect(
      registry.resolve('remote_delete', const ToolArguments('{}')).isErr,
      isTrue,
    );
  });
}
