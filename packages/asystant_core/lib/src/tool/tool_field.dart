import 'package:asystant_core/src/model/assistant_value.dart';

/// JSON-compatible field kinds supported by local argument validation.
enum ToolFieldKind { string, integer, number, boolean, strings, numbers }

/// One scalar or homogeneous-list argument accepted by a local tool.
class ToolField extends AssistantValue {
  const ToolField({
    required this.name,
    required this.description,
    required this.kind,
    this.isRequired = true,
  });

  final String name;

  final String description;

  final ToolFieldKind kind;

  final bool isRequired;

  ToolField copyWith({
    String? name,
    String? description,
    ToolFieldKind? kind,
    bool? isRequired,
  }) => ToolField(
    name: name ?? this.name,
    description: description ?? this.description,
    kind: kind ?? this.kind,
    isRequired: isRequired ?? this.isRequired,
  );

  factory ToolField.fromJson(Map<String, Object?> json) => ToolField(
    name: json['name'] as String,
    description: json['description'] as String,
    kind: ToolFieldKind.values.byName(json['kind'] as String),
    isRequired: json['is_required'] as bool,
  );

  @override
  Map<String, Object?> toJson() => {
    'name': name,
    'description': description,
    'kind': kind.name,
    'is_required': isRequired,
  };

  Map<String, Object?> toSchema() => {
    'type': switch (kind) {
      ToolFieldKind.strings || ToolFieldKind.numbers => 'array',
      ToolFieldKind.string ||
      ToolFieldKind.integer ||
      ToolFieldKind.number ||
      ToolFieldKind.boolean => kind.name,
    },
    'description': description,
    if (kind == ToolFieldKind.strings || kind == ToolFieldKind.numbers)
      'items': <String, Object?>{
        'type': kind == ToolFieldKind.strings ? 'string' : 'number',
      },
  };
}
