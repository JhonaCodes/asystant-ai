import 'package:asystant_core/src/model/assistant_value.dart';
import 'package:asystant_core/src/tool/tool_field.dart';

/// The provider-visible name, description and allowed fields of a local tool.
class ToolDefinition extends AssistantValue {
  const ToolDefinition({
    required this.name,
    required this.description,
    required this.fields,
  });
  final String name;
  final String description;
  final List<ToolField> fields;
  ToolDefinition copyWith({
    String? name,
    String? description,
    List<ToolField>? fields,
  }) => ToolDefinition(
    name: name ?? this.name,
    description: description ?? this.description,
    fields: List.unmodifiable(fields ?? this.fields),
  );
  factory ToolDefinition.fromJson(Map<String, Object?> json) => ToolDefinition(
    name: json['name'] as String,
    description: json['description'] as String,
    fields: List.unmodifiable(
      (json['fields'] as List<Object?>).map(
        (f) => ToolField.fromJson(f as Map<String, Object?>),
      ),
    ),
  );
  @override
  Map<String, Object?> toJson() => {
    'name': name,
    'description': description,
    'fields': fields.map((f) => f.toJson()).toList(),
  };
  Map<String, Object?> toSchema() => {
    'name': name,
    'description': description,
    'parameters': <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        for (final field in fields) field.name: field.toSchema(),
      },
      'required': fields.where((f) => f.isRequired).map((f) => f.name).toList(),
      'additionalProperties': false,
    },
  };
}
