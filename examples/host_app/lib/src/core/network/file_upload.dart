import 'dart:typed_data';

/// A file to send to `POST /files`, carried in `Params.model`.
class FileUpload {
  const FileUpload({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final Uint8List bytes;

  final String filename;

  final String mimeType;

  /// Lowercase extension without the dot, or empty.
  String get extension {
    final dot = filename.lastIndexOf('.');
    return dot < 0 || dot == filename.length - 1
        ? ''
        : filename.substring(dot + 1).toLowerCase();
  }

  FileUpload copyWith({Uint8List? bytes, String? filename, String? mimeType}) =>
      FileUpload(
        bytes: bytes ?? this.bytes,
        filename: filename ?? this.filename,
        mimeType: mimeType ?? this.mimeType,
      );

  /// Metadata only: the bytes never go into JSON.
  Map<String, Object?> toJson() => {
    'filename': filename,
    'mime_type': mimeType,
    'size': bytes.length,
  };

  @override
  bool operator ==(Object other) =>
      other is FileUpload &&
      filename == other.filename &&
      mimeType == other.mimeType &&
      bytes.length == other.bytes.length;

  @override
  int get hashCode => Object.hash(filename, mimeType, bytes.length);

  @override
  String toString() => 'FileUpload($filename, $mimeType, ${bytes.length} B)';
}
