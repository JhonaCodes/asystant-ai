import 'package:collection/collection.dart';

/// What an operation answered, already redacted: safe to give to the model.
///
/// Transient: it is read once by the tool that ran the operation, so it has
/// no JSON form of its own.
class BusinessOperationResponse {
  const BusinessOperationResponse({required this.statusCode, this.body});

  final int statusCode;

  /// The decoded JSON body with every secret replaced by `[redacted]`.
  final Object? body;

  BusinessOperationResponse copyWith({int? statusCode, Object? body}) =>
      BusinessOperationResponse(
        statusCode: statusCode ?? this.statusCode,
        body: body ?? this.body,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessOperationResponse &&
          statusCode == other.statusCode &&
          const DeepCollectionEquality().equals(body, other.body);

  @override
  int get hashCode =>
      Object.hash(statusCode, const DeepCollectionEquality().hash(body));
}
