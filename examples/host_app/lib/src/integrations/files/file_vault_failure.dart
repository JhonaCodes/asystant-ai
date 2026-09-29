part of 'files.dart';

/// Why a file could not be saved or removed.
class FileVaultFailure {
  const FileVaultFailure(this.message);

  final String message;

  FileVaultFailure copyWith({String? message}) =>
      FileVaultFailure(message ?? this.message);

  @override
  bool operator ==(Object other) =>
      other is FileVaultFailure && message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'FileVaultFailure($message)';
}
