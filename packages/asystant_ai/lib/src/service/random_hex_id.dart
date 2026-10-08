import 'dart:math';

final Random _secure = Random.secure();

/// [bytes] cryptographically secure random bytes as lowercase hex, two
/// characters per byte.
String randomHexId(int bytes) => List<String>.generate(
  bytes,
  (_) => _secure.nextInt(256).toRadixString(16).padLeft(2, '0'),
).join();
