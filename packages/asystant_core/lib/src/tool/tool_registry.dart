import 'package:result_controller/result_controller.dart';
import 'package:asystant_core/src/model/assistant_failure.dart';
import 'package:asystant_core/src/tool/asystant_tool.dart';
import 'package:asystant_core/src/tool/tool_arguments.dart';
import 'package:asystant_core/src/tool/tool_field.dart';

class ToolRegistry {
  ToolRegistry(Iterable<AsystantTool> tools)
    : _tools = List.unmodifiable(tools);
  final List<AsystantTool> _tools;
  List<AsystantTool> get tools => _tools;
  Result<bool, AssistantFailure> validate() {
    final names = <String>{};
    for (final tool in _tools) {
      final definition = tool.definition;
      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{0,63}$').hasMatch(definition.name) ||
          !names.add(definition.name) ||
          definition.description.trim().isEmpty)
        return Err(AssistantFailure(.invalidTool));
      if (definition.fields.map((f) => f.name).toSet().length !=
          definition.fields.length)
        return Err(AssistantFailure(.invalidTool));
    }
    return Ok(true);
  }

  Result<AsystantTool, AssistantFailure> resolve(
    String name,
    ToolArguments arguments,
  ) {
    final tool = _tools
        .where((tool) => tool.definition.name == name)
        .firstOrNull;
    if (tool == null || !tool.isAvailable)
      return Err(AssistantFailure(.invalidTool));
    try {
      final supplied = arguments.toJson();
      final fields = tool.definition.fields;
      if (supplied.keys.any((key) => !fields.any((field) => field.name == key)))
        return Err(AssistantFailure(.invalidTool));
      for (final field in fields) {
        if (!supplied.containsKey(field.name)) {
          if (field.isRequired) return Err(AssistantFailure(.invalidTool));
          continue;
        }
        final argument = supplied[field.name];
        final valid = switch (field.kind) {
          ToolFieldKind.string => argument is String,
          ToolFieldKind.integer => argument is int,
          ToolFieldKind.number => argument is num && argument.isFinite,
          ToolFieldKind.boolean => argument is bool,
          ToolFieldKind.strings =>
            argument is List<Object?> &&
                argument.every((entry) => entry is String),
        };
        if (!valid) return Err(AssistantFailure(.invalidTool));
      }
      return Ok(tool);
    } on FormatException {
      return Err(AssistantFailure(.invalidTool));
    } on TypeError {
      return Err(AssistantFailure(.invalidTool));
    }
  }
}
