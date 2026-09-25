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

  /// Schema sent to the model during initialization.
  ToolDefinition get definition;

  /// Whether the user must approve this call before execution. Defaults to true.
  bool get requiresConfirmation => true;

  /// Whether the user must choose at least one preview option.
  bool get requiresSelection => false;

  /// Whether this tool is registered for the current host context.
  bool get isAvailable => true;

  /// Builds a read-only preview; must not mutate host application state.
  Future<Result<AssistantCard, AssistantFailure>> preview(
    ToolArguments arguments,
  );

  /// Runs the authorized local action using the host application services.
  Future<Result<ToolOutcome, AssistantFailure>> execute(
    ToolArguments arguments,
    ToolContext context,
  );
}
