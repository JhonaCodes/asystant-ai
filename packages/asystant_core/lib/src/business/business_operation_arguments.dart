import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/business/business_failure.dart';
import 'package:asystant_core/src/business/business_failure_code.dart';
import 'package:asystant_core/src/business/business_field.dart';
import 'package:asystant_core/src/business/business_field_kind.dart';
import 'package:asystant_core/src/business/business_operation.dart';
import 'package:asystant_core/src/business/business_secret_name.dart';

/// Checks the arguments of one call to an operation against its fields.
extension BusinessOperationArguments on BusinessOperation {
  /// The [arguments] when they match the operation's fields exactly: no
  /// unknown member, every required one present, each of its declared type,
  /// choices and limits. Otherwise an `Err` with
  /// [BusinessFailureCode.invalidInput] naming the parameter.
  ///
  /// With [allowsMissingSecrets], `secret` fields must be absent: they are
  /// typed by the person on the device, never written by the model.
  Result<Map<String, Object?>, BusinessFailure> validateArguments(
    Map<String, Object?> arguments, {
    bool allowsMissingSecrets = false,
  }) {
    final problem = _argumentsProblem(
      arguments,
      allowsMissingSecrets: allowsMissingSecrets,
    );
    return problem == null
        ? Ok(arguments)
        : Err(BusinessFailure(.invalidInput, message: problem));
  }

  /// The names of the `secret` fields the person types for this operation.
  List<String> get secretFieldNames => [
    for (final field in fields)
      if (field.kind == BusinessFieldKind.secret) field.name,
  ];

  String? _argumentsProblem(
    Map<String, Object?> arguments, {
    required bool allowsMissingSecrets,
  }) {
    final expected = {for (final field in fields) field.name: field};
    for (final name in arguments.keys) {
      if (!expected.containsKey(name)) return 'Unexpected parameter: $name.';
    }
    for (final field in fields) {
      final value = arguments[field.name];
      if (allowsMissingSecrets && field.kind == BusinessFieldKind.secret) {
        if (value != null) return 'Enter ${field.name} on the device.';
        continue;
      }
      if (value == null) {
        if (field.isRequired) return 'Missing parameter: ${field.name}.';
        continue;
      }
      final problem = _valueProblem(field, value, field.name);
      if (problem != null) return problem;
    }
    return null;
  }

  static String? _valueProblem(BusinessField field, Object value, String path) {
    final isValid = switch (field.kind) {
      .string => value is String && value.trim().isNotEmpty,
      .secret => value is String && value.isNotEmpty,
      .integer => value is int,
      .number => value is num,
      .boolean => value is bool,
      .object => value is Map,
      .list => value is List,
    };
    if (!isValid) return 'Invalid parameter: $path (${field.kind.name}).';
    if (field.options.isNotEmpty && !field.options.contains(value)) {
      return 'Invalid choice for $path: ${field.options.join('|')}.';
    }
    final (minimum, maximum) = (field.minimum, field.maximum);
    if (value is num &&
        ((minimum != null && value < minimum) ||
            (maximum != null && value > maximum))) {
      return 'Value out of range: $path.';
    }
    return switch (value) {
      final Map<Object?, Object?> object => _objectProblem(
        field,
        object.cast<String, Object?>(),
        path,
      ),
      final List<Object?> list => _listProblem(field, list, path),
      _ => null,
    };
  }

  static String? _objectProblem(
    BusinessField field,
    Map<String, Object?> object,
    String path,
  ) {
    final expected = {
      for (final property in field.properties) property.name: property,
    };
    for (final key in object.keys) {
      if (key.isBusinessSecretName) return 'Enter $path.$key on the device.';
      if (!expected.containsKey(key) && !field.allowsAdditionalProperties) {
        return 'Unexpected parameter: $path.$key.';
      }
    }
    for (final property in field.properties) {
      final nested = object[property.name];
      if (nested == null) {
        if (property.isRequired) {
          return 'Missing parameter: $path.${property.name}.';
        }
        continue;
      }
      final problem = _valueProblem(property, nested, '$path.${property.name}');
      if (problem != null) return problem;
    }
    return null;
  }

  static String? _listProblem(
    BusinessField field,
    List<Object?> list,
    String path,
  ) {
    final item = field.item;
    if (item == null) return null;
    for (final (index, entry) in list.indexed) {
      if (entry == null) return 'Invalid parameter: $path[$index].';
      final problem = _valueProblem(item, entry, '$path[$index]');
      if (problem != null) return problem;
    }
    return null;
  }
}
