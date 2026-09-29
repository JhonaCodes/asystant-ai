part of '../ai.dart';

/// Reading the model's arguments, shared by the tools.
abstract final class _ToolInput {
  /// Longest text kept from the model: what a person says about one thing.
  static const _maxLength = 120;

  /// The non-empty strings of a JSON list, trimmed and bounded.
  static List<String> texts(Object? values) => [
    if (values case final List<Object?> list)
      for (final value in list)
        if (text(value) case final text when text.isNotEmpty) text,
  ];

  /// A trimmed, bounded string, or empty when the model sent none.
  static String text(Object? value) => switch (value) {
    final String text when text.trim().length > _maxLength =>
      text.trim().substring(0, _maxLength),
    final String text => text.trim(),
    _ => '',
  };
}
