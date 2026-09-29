part of 'local_db.dart';

/// Every record in memory, by key, so reads never cross into native code.
class KeyIndex {
  final Map<String, Map<String, Object?>> _records = {};

  void load(Iterable<MapEntry<String, Map<String, Object?>>> records) {
    _records
      ..clear()
      ..addEntries(records);
  }

  Map<String, Object?>? operator [](String key) => _records[key];

  void put(String key, Map<String, Object?> value) => _records[key] = value;

  void remove(String key) => _records.remove(key);

  /// Records whose key starts with [prefix], in key order.
  List<MapEntry<String, Map<String, Object?>>> withPrefix(String prefix) =>
      _records.entries.where((entry) => entry.key.startsWith(prefix)).toList()
        ..sort((a, b) => a.key.compareTo(b.key));
}
