import 'package:collection/collection.dart';

/// One request to a business API. Transient: it is built for one call and
/// never serialized, so it has no JSON form.
class BusinessHttpRequest {
  const BusinessHttpRequest({
    required this.method,
    required this.uri,
    this.headers = const {},
    this.body,
  });

  /// `GET`, `POST`, `PUT`, `PATCH` or `DELETE`.
  final String method;

  final Uri uri;

  final Map<String, String> headers;

  /// A JSON value sent as the body; null sends none.
  final Object? body;

  /// `scheme://host/path` of [uri], without query or credentials, for
  /// failure messages.
  String get address => '${uri.scheme}://${uri.host}${uri.path}';

  BusinessHttpRequest copyWith({
    String? method,
    Uri? uri,
    Map<String, String>? headers,
    Object? body,
  }) => BusinessHttpRequest(
    method: method ?? this.method,
    uri: uri ?? this.uri,
    headers: headers ?? this.headers,
    body: body ?? this.body,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessHttpRequest &&
          method == other.method &&
          uri == other.uri &&
          const MapEquality<String, String>().equals(headers, other.headers) &&
          const DeepCollectionEquality().equals(body, other.body);

  @override
  int get hashCode => Object.hash(
    method,
    uri,
    const MapEquality<String, String>().hash(headers),
    const DeepCollectionEquality().hash(body),
  );
}
