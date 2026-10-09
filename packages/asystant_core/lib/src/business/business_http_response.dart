import 'package:collection/collection.dart';

/// What a business API answered. Transient: it is read once and never
/// serialized, so it has no JSON form.
class BusinessHttpResponse {
  const BusinessHttpResponse({required this.statusCode, this.body});

  final int statusCode;

  /// The decoded JSON body; the raw text when it is not JSON; null when
  /// empty.
  final Object? body;

  /// Whether the status is 2xx.
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  BusinessHttpResponse copyWith({int? statusCode, Object? body}) =>
      BusinessHttpResponse(
        statusCode: statusCode ?? this.statusCode,
        body: body ?? this.body,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessHttpResponse &&
          statusCode == other.statusCode &&
          const DeepCollectionEquality().equals(body, other.body);

  @override
  int get hashCode =>
      Object.hash(statusCode, const DeepCollectionEquality().hash(body));
}
