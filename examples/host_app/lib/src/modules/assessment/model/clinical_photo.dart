/// A photo taken for the assessment, e.g. of a skin irritation.
class ClinicalPhoto {
  const ClinicalPhoto({
    required this.id,
    required this.ref,
    required this.takenAt,
    this.caption = '',
    this.bodyArea = '',
  });

  factory ClinicalPhoto.fromJson(Map<String, Object?> json) => ClinicalPhoto(
    id: json['id'] as String,
    ref: json['ref'] as String,
    takenAt: DateTime.parse(json['takenAt'] as String),
    caption: json['caption'] as String? ?? '',
    bodyArea: json['bodyArea'] as String? ?? '',
  );

  /// The backend's file id.
  final String id;

  final String ref;

  final DateTime takenAt;

  final String caption;

  final String bodyArea;

  ClinicalPhoto copyWith({
    String? id,
    String? ref,
    DateTime? takenAt,
    String? caption,
    String? bodyArea,
  }) => ClinicalPhoto(
    id: id ?? this.id,
    ref: ref ?? this.ref,
    takenAt: takenAt ?? this.takenAt,
    caption: caption ?? this.caption,
    bodyArea: bodyArea ?? this.bodyArea,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'ref': ref,
    'takenAt': takenAt.toUtc().toIso8601String(),
    'caption': caption,
    'bodyArea': bodyArea,
  };

  @override
  bool operator ==(Object other) =>
      other is ClinicalPhoto &&
      id == other.id &&
      ref == other.ref &&
      takenAt == other.takenAt &&
      caption == other.caption &&
      bodyArea == other.bodyArea;

  @override
  int get hashCode => Object.hash(id, ref, takenAt, caption, bodyArea);

  @override
  String toString() => 'ClinicalPhoto($id)';
}
