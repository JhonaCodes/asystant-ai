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

  /// The string at [key]. Throws a [TypeError] if the value is missing or
  /// not a string.
  String string(String key) => toJson()[key] as String;

  /// The number at [key]. Throws a [TypeError] if the value is missing or
  /// not a number.
  num number(String key) => toJson()[key] as num;

  /// The boolean at [key]. Throws a [TypeError] if the value is missing or
  /// not a boolean.
  bool boolean(String key) => toJson()[key] as bool;

  /// The string list at [key], or an empty list if [key] is absent. Throws a
  /// [TypeError] if the value is present and not a list of strings.
  List<String> strings(String key) =>
      (toJson()[key] as List<Object?>? ?? const []).cast<String>();

  /// The numeric list at [key], as doubles. Throws a [TypeError] if the
  /// value is missing or not a list of numbers.
  List<double> numbers(String key) => (toJson()[key] as List<Object?>)
      .map((value) => (value as num).toDouble())
      .toList();

  ToolArguments copyWith({String? encoded}) =>
      ToolArguments(encoded ?? this.encoded);
}
