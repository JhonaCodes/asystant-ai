import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// A file the person attached to a message.
///
/// Equality and JSON cover the metadata only: the bytes never travel through
/// logs, state comparisons or serialized transcripts.
class AsystantAttachment {
  const AsystantAttachment({
    required this.id,
    required this.filename,
    required this.mimeType,
    required this.bytes,
  });

  /// Builds an attachment with a new id, guessing the type from [filename]
  /// when [mimeType] is not given.
  factory AsystantAttachment.fromBytes({
    required Uint8List bytes,
    required String filename,
    String? mimeType,
  }) => AsystantAttachment(
    id: _newId(),
    filename: filename,
    mimeType: mimeType ?? mimeTypeOf(filename),
    bytes: bytes,
  );

  final String id;

  final String filename;

  final String mimeType;

  final Uint8List bytes;

  int get size => bytes.length;

  /// Lowercase extension without the dot, or empty.
  String get extension => extensionOf(filename);

  bool get isImage => mimeType.startsWith('image/');

  bool get isPdf => mimeType == 'application/pdf';

  bool get isAudio => mimeType.startsWith('audio/');

  /// Plain text the model can read directly: text, CSV, JSON, code.
  bool get isText =>
      mimeType.startsWith('text/') || _textTypes.contains(mimeType);

  /// The file's text for [isText] files; invalid bytes are replaced.
  String get text => utf8.decode(bytes, allowMalformed: true);

  static String extensionOf(String filename) {
    final dot = filename.lastIndexOf('.');
    return dot < 0 || dot == filename.length - 1
        ? ''
        : filename.substring(dot + 1).toLowerCase();
  }

  /// A best guess from the extension; `application/octet-stream` otherwise.
  static String mimeTypeOf(String filename) =>
      _mimeTypes[extensionOf(filename)] ?? 'application/octet-stream';

  static const _textTypes = {
    'application/json',
    'application/xml',
    'application/yaml',
    'application/x-yaml',
    'application/javascript',
    'application/sql',
  };

  static const _mimeTypes = {
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'pdf': 'application/pdf',
    'txt': 'text/plain',
    'md': 'text/markdown',
    'csv': 'text/csv',
    'tsv': 'text/tab-separated-values',
    'html': 'text/html',
    'css': 'text/css',
    'json': 'application/json',
    'xml': 'application/xml',
    'yaml': 'application/yaml',
    'yml': 'application/yaml',
    'js': 'application/javascript',
    'sql': 'application/sql',
    'dart': 'text/x-dart',
    'rs': 'text/x-rust',
    'py': 'text/x-python',
    'ts': 'text/x-typescript',
    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'm4a': 'audio/mp4',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'xls': 'application/vnd.ms-excel',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'doc': 'application/msword',
    'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'zip': 'application/zip',
  };

  static String _newId() {
    final random = Random.secure();
    return List.generate(
      12,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  AsystantAttachment copyWith({
    String? id,
    String? filename,
    String? mimeType,
    Uint8List? bytes,
  }) => AsystantAttachment(
    id: id ?? this.id,
    filename: filename ?? this.filename,
    mimeType: mimeType ?? this.mimeType,
    bytes: bytes ?? this.bytes,
  );

  /// Metadata only; see the class comment.
  Map<String, Object?> toJson() => {
    'id': id,
    'filename': filename,
    'mime_type': mimeType,
    'size': size,
  };

  @override
  bool operator ==(Object other) =>
      other is AsystantAttachment &&
      id == other.id &&
      filename == other.filename &&
      mimeType == other.mimeType &&
      size == other.size;

  @override
  int get hashCode => Object.hash(id, filename, mimeType, size);

  @override
  String toString() => 'AsystantAttachment($filename, $mimeType, $size B)';
}
