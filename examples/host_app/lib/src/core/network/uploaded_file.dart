/// A file the backend kept: its id and where to read it from.
class UploadedFile {
  const UploadedFile({
    required this.id,
    required this.ref,
    required this.mimeType,
    required this.size,
  });

  factory UploadedFile.fromJson(Map<String, Object?> json) => UploadedFile(
    id: json['id'] as String,
    ref: json['ref'] as String,
    mimeType: json['mime_type'] as String,
    size: json['size'] as int,
  );

  final String id;

  /// `local://…` from this device, `https://…` from a remote backend.
  final String ref;

  final String mimeType;

  final int size;

  UploadedFile copyWith({
    String? id,
    String? ref,
    String? mimeType,
    int? size,
  }) => UploadedFile(
    id: id ?? this.id,
    ref: ref ?? this.ref,
    mimeType: mimeType ?? this.mimeType,
    size: size ?? this.size,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'ref': ref,
    'mime_type': mimeType,
    'size': size,
  };

  @override
  bool operator ==(Object other) =>
      other is UploadedFile &&
      id == other.id &&
      ref == other.ref &&
      mimeType == other.mimeType &&
      size == other.size;

  @override
  int get hashCode => Object.hash(id, ref, mimeType, size);

  @override
  String toString() => 'UploadedFile($id, $ref)';
}
