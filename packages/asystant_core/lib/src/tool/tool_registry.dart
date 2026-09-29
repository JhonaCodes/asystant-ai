import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/model/assistant_failure.dart';
import 'package:asystant_core/src/tool/asystant_tool.dart';
import 'package:asystant_core/src/tool/tool_arguments.dart';
import 'package:asystant_core/src/tool/tool_field.dart';

/// Validates tool names and arguments before dispatching to registered local tools.
///
/// A rejected call is an [AssistantFailure] whose `detail` says what was
/// wrong (an unknown tool, a missing or unexpected argument, a wrong type, a
/// value outside its options), so the model can correct the call in its next
/// round instead of guessing.
class ToolRegistry {
  ToolRegistry(Iterable<AsystantTool> tools)
    : _tools = List.unmodifiable(tools);

  final List<AsystantTool> _tools;

  List<AsystantTool> get tools => _tools;

  Result<bool, AssistantFailure> validate() {
    final names = <String>{};
    for (final tool in _tools) {
      final definition = tool.definition;
      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{0,63}$').hasMatch(definition.name) ||
          !names.add(definition.name) ||
          definition.description.trim().isEmpty ||
          !_hasUniqueNames(definition.fields)) {
        return Err(AssistantFailure(.invalidTool));
      }
    }
    return Ok(true);
  }

  static bool _hasUniqueNames(List<ToolField> fields) =>
      fields.map((f) => f.name).toSet().length == fields.length &&
      fields.every((field) => _hasUniqueNames(field.fields));

  Result<AsystantTool, AssistantFailure> resolve(
    String name,
    ToolArguments arguments,
  ) {
    final tool = _tools
        .where((tool) => tool.definition.name == name)
        .firstOrNull;
    if (tool == null) {
      final available = [
        for (final tool in _tools)
          if (tool.isAvailable) tool.definition.name,
      ];
      return Err(
        AssistantFailure(
          .invalidTool,
          detail:
              'There is no tool named "$name". Available tools: '
              '${available.join(', ')}.',
        ),
      );
    }
    if (!tool.isAvailable) {
      return Err(
        AssistantFailure(
          .invalidTool,
          detail: 'The tool "$name" is not available right now.',
        ),
      );
    }
    try {
      return switch (_problem(tool.definition.fields, arguments.toJson())) {
        final String problem => Err(
          AssistantFailure(.invalidTool, detail: '$name: $problem'),
        ),
        null => Ok(tool),
      };
    } on FormatException {
      return Err(
        AssistantFailure(
          .invalidTool,
          detail: '$name: arguments are not JSON.',
        ),
      );
    } on TypeError {
      return Err(
        AssistantFailure(
          .invalidTool,
          detail: '$name: arguments must be a JSON object.',
        ),
      );
    }
  }

  /// What is wrong with [supplied] against [fields], or null when valid.
  ///
  /// A null value for an optional field counts as absent: models often send
  /// `null` for an argument they mean to omit.
  static String? _problem(
    List<ToolField> fields,
    Map<String, Object?> supplied, {
    String path = '',
  }) {
    for (final key in supplied.keys) {
      if (!fields.any((field) => field.name == key)) {
        return 'unexpected argument "$path$key". Accepted: '
            '${fields.map((field) => field.name).join(', ')}.';
      }
    }
    for (final field in fields) {
      final argument = supplied[field.name];
      if (argument == null) {
        if (field.isRequired) {
          return 'missing required argument "$path${field.name}".';
        }
        continue;
      }
      if (_valueProblem(field, argument, path: '$path${field.name}')
          case final String problem) {
        return problem;
      }
    }
    return null;
  }

  static String? _valueProblem(
    ToolField field,
    Object argument, {
    required String path,
  }) {
    final valid = switch (field.kind) {
      ToolFieldKind.string => argument is String,
      ToolFieldKind.integer => argument is int,
      ToolFieldKind.number => argument is num && argument.isFinite,
      ToolFieldKind.boolean => argument is bool,
      ToolFieldKind.numbers =>
        argument is List<Object?> &&
            argument.every((entry) => entry is num && entry.isFinite),
      ToolFieldKind.strings =>
        argument is List<Object?> && argument.every((entry) => entry is String),
      ToolFieldKind.objects =>
        argument is List<Object?> &&
            argument.every((entry) => entry is Map<String, Object?>),
    };
    if (!valid) {
      return '"$path" must be ${_expected(field.kind)}.';
    }
    final outside = switch (argument) {
      final String value
          when field.options.isNotEmpty && !field.options.contains(value) =>
        value,
      final List<Object?> values when field.options.isNotEmpty =>
        values
            .whereType<String>()
            .where((v) => !field.options.contains(v))
            .firstOrNull,
      _ => null,
    };
    if (outside != null) {
      return '"$path" does not accept "$outside". Valid values: '
          '${field.options.join(', ')}.';
    }
    if (field.kind == ToolFieldKind.objects && argument is List<Object?>) {
      for (final (index, entry) in argument.indexed) {
        if (_problem(
              field.fields,
              entry as Map<String, Object?>,
              path: '$path[$index].',
            )
            case final String problem) {
          return problem;
        }
      }
    }
    return null;
  }

  static String _expected(ToolFieldKind kind) => switch (kind) {
    ToolFieldKind.string => 'a string',
    ToolFieldKind.integer => 'an integer',
    ToolFieldKind.number => 'a finite number',
    ToolFieldKind.boolean => 'true or false',
    ToolFieldKind.strings => 'a list of strings',
    ToolFieldKind.numbers => 'a list of finite numbers',
    ToolFieldKind.objects => 'a list of objects',
  };
}
