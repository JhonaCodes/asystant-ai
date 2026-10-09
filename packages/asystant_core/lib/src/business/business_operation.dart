import 'package:collection/collection.dart';

import 'package:asystant_core/src/business/business_field.dart';
import 'package:asystant_core/src/business/business_json_reading.dart';

/// One registered endpoint of a business API: `METHOD path` with its typed
/// [fields] and the headers it adds to the environment's own.
class BusinessOperation {
  const BusinessOperation({
    required this.id,
    required this.name,
    required this.method,
    required this.path,
    this.fields = const [],
    this.headers = const {},
    this.privateHeaders = const [],
  });

  /// Stable identifier the model calls it by, such as `list_users`.
  final String id;

  /// What it does, for the person and the model.
  final String name;

  /// `GET`, `POST`, `PUT`, `PATCH` or `DELETE`, upper case.
  final String method;

  /// Starts with `/`; `{name}` marks a path field.
  final String path;

  final List<BusinessField> fields;

  /// Public headers sent with this operation only.
  final Map<String, String> headers;

  /// Names of headers whose values live in the device vault.
  final List<String> privateHeaders;

  /// Whether the operation only reads.
  bool get isRead => method == 'GET';

  /// Whether the operation cannot be undone: a `DELETE`.
  bool get isDestructive => method == 'DELETE';

  factory BusinessOperation.fromJson(Map<String, Object?> json) =>
      BusinessOperation(
        id: json.requiredString('id'),
        name: json.requiredString('name'),
        method: json.requiredString('method').toUpperCase(),
        path: json.requiredString('path'),
        fields: [
          for (final field in json.objectList('fields'))
            BusinessField.fromJson(field),
        ],
        headers: json.stringMap('headers'),
        privateHeaders: json.stringList('private_headers'),
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'method': method,
    'path': path,
    'fields': fields.map((field) => field.toJson()).toList(),
    if (headers.isNotEmpty) 'headers': headers,
    if (privateHeaders.isNotEmpty) 'private_headers': privateHeaders,
  };

  BusinessOperation copyWith({
    String? id,
    String? name,
    String? method,
    String? path,
    List<BusinessField>? fields,
    Map<String, String>? headers,
    List<String>? privateHeaders,
  }) => BusinessOperation(
    id: id ?? this.id,
    name: name ?? this.name,
    method: method ?? this.method,
    path: path ?? this.path,
    fields: fields ?? this.fields,
    headers: headers ?? this.headers,
    privateHeaders: privateHeaders ?? this.privateHeaders,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessOperation &&
          id == other.id &&
          name == other.name &&
          method == other.method &&
          path == other.path &&
          const ListEquality<BusinessField>().equals(fields, other.fields) &&
          const MapEquality<String, String>().equals(headers, other.headers) &&
          const UnorderedIterableEquality<String>().equals(
            privateHeaders,
            other.privateHeaders,
          );

  @override
  int get hashCode => Object.hash(
    id,
    name,
    method,
    path,
    Object.hashAll(fields),
    const MapEquality<String, String>().hash(headers),
    const UnorderedIterableEquality<String>().hash(privateHeaders),
  );
}
