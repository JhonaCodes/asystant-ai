/// Reads values out of an API answer by a dotted path such as `session.id`.
extension BusinessJsonPath on Object? {
  /// The value at [path] (`user.role`), or null when a segment is missing or
  /// is not an object.
  Object? valueAtPath(String path) {
    Object? value = this;
    for (final segment in path.split('.')) {
      if (value is! Map) return null;
      value = value[segment];
    }
    return value;
  }

  /// The non-empty string at [path], or null.
  String? textAtPath(String path) => switch (valueAtPath(path)) {
    final String text when text.isNotEmpty => text,
    _ => null,
  };

  /// The `data` member when the API wraps its answer as `{"data": {...}}`,
  /// else this value unchanged.
  Object? get withoutDataEnvelope => switch (this) {
    {'data': final Map<Object?, Object?> data} => data,
    _ => this,
  };
}
