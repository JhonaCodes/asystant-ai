import 'package:asystant_core/src/model/assistant_value.dart';

/// JSON-compatible field kinds supported by local argument validation.
///
/// [objects] is a list of objects, each with the item fields declared in
/// [ToolField.fields].
enum ToolFieldKind {
  string,
  integer,
  number,
  boolean,
  strings,
  numbers,
  objects,
}

/// One argument accepted by a local tool: a scalar, a homogeneous list, or a
/// list of objects with their own fields.
class ToolField extends AssistantValue {
  const ToolField({
    required this.name,
    required this.description,
    required this.kind,
    this.isRequired = true,
    this.options = const [],
    this.fields = const [],
  });

  final String name;

  final String description;

  final ToolFieldKind kind;

  final bool isRequired;

  /// The only values accepted, for [ToolFieldKind.string] and each entry of
  /// [ToolFieldKind.strings]; any value when empty. Sent as the schema's
  /// `enum`, and named in the validation failure the model reads.
  final List<String> options;

  /// The fields of each object, for [ToolFieldKind.objects]; ignored by
  /// every other kind.
  final List<ToolField> fields;

  ToolField copyWith({
    String? name,
    String? description,
    ToolFieldKind? kind,
    bool? isRequired,
    List<String>? options,
    List<ToolField>? fields,
  }) => ToolField(
    name: name ?? this.name,
    description: description ?? this.description,
    kind: kind ?? this.kind,
    isRequired: isRequired ?? this.isRequired,
    options: List.unmodifiable(options ?? this.options),
    fields: List.unmodifiable(fields ?? this.fields),
  );

  factory ToolField.fromJson(Map<String, Object?> json) => ToolField(
    name: json['name'] as String,
    description: json['description'] as String,
    kind: ToolFieldKind.values.byName(json['kind'] as String),
    isRequired: json['is_required'] as bool,
    options: List.unmodifiable(
      (json['options'] as List<Object?>? ?? const []).cast<String>(),
    ),
    fields: List.unmodifiable(
      (json['fields'] as List<Object?>? ?? const []).map(
        (field) => ToolField.fromJson(field as Map<String, Object?>),
      ),
    ),
  );

  @override
  Map<String, Object?> toJson() => {
    'name': name,
    'description': description,
    'kind': kind.name,
    'is_required': isRequired,
    if (options.isNotEmpty) 'options': options,
    if (fields.isNotEmpty) 'fields': fields.map((f) => f.toJson()).toList(),
  };

  Map<String, Object?> toSchema() => {
    'type': switch (kind) {
      ToolFieldKind.strings ||
      ToolFieldKind.numbers ||
      ToolFieldKind.objects => 'array',
      ToolFieldKind.string ||
      ToolFieldKind.integer ||
      ToolFieldKind.number ||
      ToolFieldKind.boolean => kind.name,
    },
    'description': description,
    if (kind == ToolFieldKind.string && options.isNotEmpty) 'enum': options,
    if (_items() case final Map<String, Object?> items) 'items': items,
  };

  /// The schema of one list entry; null for a scalar.
  Map<String, Object?>? _items() => switch (kind) {
    ToolFieldKind.strings => {
      'type': 'string',
      if (options.isNotEmpty) 'enum': options,
    },
    ToolFieldKind.numbers => const {'type': 'number'},
    ToolFieldKind.objects => {
      'type': 'object',
      'properties': {for (final field in fields) field.name: field.toSchema()},
      'required': [
        for (final field in fields)
          if (field.isRequired) field.name,
      ],
      'additionalProperties': false,
    },
    ToolFieldKind.string ||
    ToolFieldKind.integer ||
    ToolFieldKind.number ||
    ToolFieldKind.boolean => null,
  };
}
