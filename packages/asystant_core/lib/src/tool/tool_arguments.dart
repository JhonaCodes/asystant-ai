import 'dart:convert';

import 'package:asystant_core/src/model/assistant_value.dart';

/// Immutable JSON boundary. Typed tools decode this once into their own input.
class ToolArguments extends AssistantValue {
  const ToolArguments(this.encoded);
  final String encoded;
  factory ToolArguments.fromJson(Map<String, Object?> json) =>
      ToolArguments(jsonEncode(json));
  @override
  Map<String, Object?> toJson() =>
      (jsonDecode(encoded) as Map<String, Object?>);
  String string(String key) => toJson()[key] as String;
  num number(String key) => toJson()[key] as num;
  bool boolean(String key) => toJson()[key] as bool;
  List<String> strings(String key) =>
      (toJson()[key] as List<Object?>? ?? const []).cast<String>();
  ToolArguments copyWith({String? encoded}) =>
      ToolArguments(encoded ?? this.encoded);
}
