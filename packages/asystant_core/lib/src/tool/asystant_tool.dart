import 'package:result_controller/result_controller.dart';
import 'package:asystant_core/src/model/assistant_card.dart';
import 'package:asystant_core/src/model/assistant_failure.dart';
import 'package:asystant_core/src/tool/tool_arguments.dart';
import 'package:asystant_core/src/tool/tool_context.dart';
import 'package:asystant_core/src/tool/tool_definition.dart';
import 'package:asystant_core/src/tool/tool_outcome.dart';

/// Implement locally. Preview must be read-only; execute uses the host's services.
abstract class AsystantTool {
  const AsystantTool();
  ToolDefinition get definition;
  bool get requiresConfirmation => true;
  bool get requiresSelection => false;
  bool get isAvailable => true;
  Future<Result<AssistantCard, AssistantFailure>> preview(
    ToolArguments arguments,
  );
  Future<Result<ToolOutcome, AssistantFailure>> execute(
    ToolArguments arguments,
    ToolContext context,
  );
}
