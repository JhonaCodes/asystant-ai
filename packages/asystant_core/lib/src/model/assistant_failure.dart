import 'package:asystant_core/src/model/assistant_value.dart';

enum FailureCode {
  authentication,
  budget,
  network,
  protocol,
  unavailable,
  invalidTool,
  toolFailed,
  canceled,
  limit,
}

class AssistantFailure extends AssistantValue implements Exception {
  const AssistantFailure(this.code, {this.detail = ''});
  final FailureCode code;
  final String detail;
  AssistantFailure copyWith({FailureCode? code, String? detail}) =>
      AssistantFailure(code ?? this.code, detail: detail ?? this.detail);
  factory AssistantFailure.fromJson(Map<String, Object?> json) =>
      AssistantFailure(
        FailureCode.values.byName(json['code'] as String),
        detail: json['detail'] as String? ?? '',
      );
  @override
  Map<String, Object?> toJson() => {'code': code.name, 'detail': detail};
  @override
  String toString() => 'AssistantFailure(${code.name})';
}
