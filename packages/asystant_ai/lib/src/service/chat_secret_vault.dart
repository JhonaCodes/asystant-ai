import 'dart:math';

import 'package:asystant_core/asystant_core.dart';

/// Keeps `$value` chat secrets in memory, outside conversation state and stores.
/// Only a local tool execution may exchange a reference for its value.
class ChatSecretVault {
  static final _literal = RegExp(r'\$([A-Za-z0-9_./+=:@-]{4,})');
  static final _reference = RegExp(r'^\[secret:([a-f0-9]{32})\]$');
  final _random = Random.secure();
  final Map<String, Map<String, String>> _values = {};

  /// Reserves a value entered through the private sheet without ever placing
  /// that value in the chat draft, conversation or provider request.
  String reserve(String conversationId, String value) {
    final id = List<int>.generate(
      16,
      (_) => _random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    final reference = '[secret:$id]';
    _values.putIfAbsent(conversationId, () => {})[reference] = value;
    return reference;
  }

  String protect(String conversationId, String content) {
    return content.replaceAllMapped(_literal, (match) {
      return reserve(conversationId, match.group(1)!);
    });
  }

  /// Returns null if a referenced secret has expired (e.g. after an app restart).
  ToolArguments? resolve(
    String conversationId,
    ToolArguments arguments,
    List<ToolField> fields,
  ) {
    var missing = false;
    ToolField? fieldNamed(List<ToolField> candidates, String name) {
      for (final field in candidates) {
        if (field.name == name) return field;
      }
      return null;
    }

    Object? visit(Object? value, ToolField? field) {
      if (value is String) {
        if (!_reference.hasMatch(value)) {
          if (value.contains('[secret:')) missing = true;
          return value;
        }
        if (field?.acceptsSecret != true) {
          missing = true;
          return null;
        }
        final secret = _values[conversationId]?[value];
        if (secret == null) missing = true;
        return secret;
      }
      if (value is List)
        return value.map((child) => visit(child, field)).toList();
      if (value is Map) {
        return value.map(
          (key, child) => MapEntry(
            key.toString(),
            visit(child, fieldNamed(field?.fields ?? const [], key.toString())),
          ),
        );
      }
      return value;
    }

    final resolved = arguments.toJson().map(
      (key, value) => MapEntry(key, visit(value, fieldNamed(fields, key))),
    );
    if (missing) return null;
    return ToolArguments.fromJson(resolved);
  }

  bool containsReference(ToolArguments arguments) {
    bool visit(Object? value) {
      if (value is String) return _reference.hasMatch(value);
      if (value is List) return value.any(visit);
      if (value is Map) return value.values.any(visit);
      return false;
    }

    return visit(arguments.toJson());
  }

  /// Scrubs tool output before it reaches the timeline, store or model.
  String redact(String conversationId, String text) {
    var safe = text;
    for (final entry
        in _values[conversationId]?.entries ??
            const <MapEntry<String, String>>[]) {
      safe = safe.replaceAll(entry.value, entry.key);
    }
    return safe;
  }

  Object? redactValue(String conversationId, Object? value) {
    if (value is String) return redact(conversationId, value);
    if (value is List) {
      return value.map((child) => redactValue(conversationId, child)).toList();
    }
    if (value is Map) {
      return value.map(
        (key, child) =>
            MapEntry(key.toString(), redactValue(conversationId, child)),
      );
    }
    return value;
  }

  void forget(String conversationId) => _values.remove(conversationId);

  void clear() => _values.clear();
}
