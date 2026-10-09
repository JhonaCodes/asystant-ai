/// Checks the names of the headers a contract declares or a person saves.
extension BusinessHeaderName on String {
  static final RegExp _name = RegExp(r'^[A-Za-z][A-Za-z0-9-]{0,63}$');

  static const Set<String> _reserved = {
    'host',
    'content-length',
    'connection',
    'authorization',
    'content-type',
    'idempotency-key',
  };

  /// Whether this is a valid header name that a contract may set: letters,
  /// digits and dashes, and none of the headers the library sets itself
  /// (`Authorization`, `Content-Type`, `Idempotency-Key`, ...).
  bool get isBusinessHeaderName =>
      _name.hasMatch(this) && !_reserved.contains(toLowerCase());
}
