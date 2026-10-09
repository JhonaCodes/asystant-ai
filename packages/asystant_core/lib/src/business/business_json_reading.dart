/// Reads the members of a business contract's JSON, throwing a
/// [FormatException] that names the member when its type is wrong. Used
/// only by the `fromJson` constructors; `BusinessContract.parse` turns the
/// exception into a `Result` at the boundary.
extension BusinessJsonReading on Map<String, Object?> {
  String requiredString(String key) => switch (this[key]) {
    final String value => value,
    _ => throw FormatException('"$key" must be a string'),
  };

  String optionalString(String key, String fallback) => switch (this[key]) {
    null => fallback,
    final String value => value,
    _ => throw FormatException('"$key" must be a string'),
  };

  bool optionalBool(String key, {required bool fallback}) =>
      switch (this[key]) {
        null => fallback,
        final bool value => value,
        _ => throw FormatException('"$key" must be true or false'),
      };

  /// A JSON object of strings; numbers and booleans are kept as text.
  Map<String, String> stringMap(String key) => switch (this[key]) {
    null => const {},
    final Map<Object?, Object?> value => {
      for (final entry in value.entries) '${entry.key}': '${entry.value}',
    },
    _ => throw FormatException('"$key" must be an object'),
  };

  List<String> stringList(String key) => switch (this[key]) {
    null => const [],
    final List<Object?> value => [
      for (final entry in value)
        if (entry is String)
          entry
        else
          throw FormatException('"$key" must be a list of strings'),
    ],
    _ => throw FormatException('"$key" must be a list'),
  };

  List<Map<String, Object?>> objectList(String key) => switch (this[key]) {
    null => const [],
    final List<Object?> value => [
      for (final entry in value)
        if (entry is Map)
          entry.cast<String, Object?>()
        else
          throw FormatException('"$key" must be a list of objects'),
    ],
    _ => throw FormatException('"$key" must be a list'),
  };

  Map<String, Object?>? optionalObject(String key) => switch (this[key]) {
    null => null,
    final Map<Object?, Object?> value => value.cast<String, Object?>(),
    _ => throw FormatException('"$key" must be an object'),
  };

  /// The value of [values] named by the string at [key], or [fallback]
  /// when the member is absent.
  T enumValue<T extends Enum>(List<T> values, String key, {T? fallback}) {
    final name = this[key];
    if (name == null && fallback != null) return fallback;
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw FormatException(
      '"$key" must be one of ${values.map((value) => value.name).join('|')}',
    );
  }
}
