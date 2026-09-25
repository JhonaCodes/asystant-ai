import 'package:result_controller/result_controller.dart';
import 'package:asystant_core/src/model/assistant_card.dart';
import 'package:asystant_core/src/model/assistant_failure.dart';
import 'package:asystant_core/src/tool/asystant_tool.dart';
import 'package:asystant_core/src/tool/tool_arguments.dart';
import 'package:asystant_core/src/tool/tool_context.dart';
import 'package:asystant_core/src/tool/tool_outcome.dart';

/// A tool that decodes untrusted JSON arguments into a domain input type.
abstract class TypedAsystantTool<T> extends AsystantTool {
  const TypedAsystantTool();

  /// Validates and converts JSON arguments into the domain input type.
  Result<T, AssistantFailure> decode(ToolArguments arguments);

  /// Builds a read-only preview from a successfully decoded input.
  Future<Result<AssistantCard, AssistantFailure>> previewInput(T input);

  /// Executes the authorized domain operation after successful decoding.
  Future<Result<ToolOutcome, AssistantFailure>> executeInput(
    T input,
    ToolContext context,
  );
  @override
  Future<Result<AssistantCard, AssistantFailure>> preview(
    ToolArguments arguments,
  ) =>
      decode(arguments)
          .when(ok: previewInput, err: (failure) async => Err(failure));
  @override
  Future<Result<ToolOutcome, AssistantFailure>> execute(
    ToolArguments arguments,
    ToolContext context,
  ) => decode(arguments).when(
    ok: (input) => executeInput(input, context),
    err: (failure) async => Err(failure),
  );
}
