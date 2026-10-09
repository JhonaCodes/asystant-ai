import 'package:asystant_core/src/business/business_failure_code.dart';

/// A typed business failure, safe to show to the person and to give to the
/// model: [message] never carries headers, credentials, codes or bodies
/// with secrets.
class BusinessFailure {
  const BusinessFailure(
    this.code, {
    this.message = '',
    this.statusCode,
    this.address = '',
  });

  final BusinessFailureCode code;

  /// What went wrong, in one sentence the person or the model can act on.
  final String message;

  /// The HTTP status the API answered, when it answered.
  final int? statusCode;

  /// `scheme://host/path` of the request that failed, without query or
  /// credentials; empty when no request was sent.
  final String address;

  BusinessFailure copyWith({
    BusinessFailureCode? code,
    String? message,
    int? statusCode,
    String? address,
  }) => BusinessFailure(
    code ?? this.code,
    message: message ?? this.message,
    statusCode: statusCode ?? this.statusCode,
    address: address ?? this.address,
  );

  factory BusinessFailure.fromJson(Map<String, Object?> json) =>
      BusinessFailure(
        BusinessFailureCode.values.byName(json['code'] as String),
        message: json['message'] as String? ?? '',
        statusCode: json['status_code'] as int?,
        address: json['address'] as String? ?? '',
      );

  Map<String, Object?> toJson() => {
    'code': code.name,
    if (message.isNotEmpty) 'message': message,
    'status_code': ?statusCode,
    if (address.isNotEmpty) 'address': address,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessFailure &&
          code == other.code &&
          message == other.message &&
          statusCode == other.statusCode &&
          address == other.address;

  @override
  int get hashCode => Object.hash(code, message, statusCode, address);

  @override
  String toString() => 'BusinessFailure(${code.name}: $message)';
}
