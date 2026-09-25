import 'package:asystant_core/src/model/assistant_value.dart';
import 'package:asystant_core/src/tool/tool_arguments.dart';

/// A model-proposed local function call whose arguments must be validated before use.
class ToolCall extends AssistantValue {
  const ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  final String id;

  final String name;

  final ToolArguments arguments;

  ToolCall copyWith({String? id, String? name, ToolArguments? arguments}) =>
      ToolCall(
        id: id ?? this.id,
        name: name ?? this.name,
        arguments: arguments ?? this.arguments,
      );

  factory ToolCall.fromJson(Map<String, Object?> json) => ToolCall(
    id: json['id'] as String,
    name: json['name'] as String,
    arguments: ToolArguments.fromJson(
      json['arguments'] as Map<String, Object?>,
    ),
  );

  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'arguments': arguments.toJson(),
  };
}
