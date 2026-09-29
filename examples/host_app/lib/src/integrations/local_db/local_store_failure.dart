part of 'local_db.dart';

/// Why the local database could not do what was asked.
class LocalStoreFailure {
  const LocalStoreFailure({required this.kind, required this.message});

  final LocalStoreFailureKind kind;

  final String message;

  LocalStoreFailure copyWith({LocalStoreFailureKind? kind, String? message}) =>
      LocalStoreFailure(
        kind: kind ?? this.kind,
        message: message ?? this.message,
      );

  @override
  bool operator ==(Object other) =>
      other is LocalStoreFailure &&
      kind == other.kind &&
      message == other.message;

  @override
  int get hashCode => Object.hash(kind, message);

  @override
  String toString() => 'LocalStoreFailure(${kind.name}: $message)';
}

enum LocalStoreFailureKind { unavailable, notOpen, write }
