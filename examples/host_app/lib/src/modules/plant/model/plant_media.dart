import 'package:host_app/src/modules/plant/model/plant_enums.dart';

/// A photo of the plant and who took it.
class PlantPhoto {
  const PlantPhoto({
    required this.ref,
    this.fileId = '',
    this.author = '',
    this.license = '',
    this.licenseUrl = '',
    this.sourceUrl = '',
    this.caption = '',
  });

  factory PlantPhoto.fromJson(Map<String, Object?> json) => PlantPhoto(
    ref: json['ref'] as String,
    fileId: json['fileId'] as String? ?? '',
    author: json['author'] as String? ?? '',
    license: json['license'] as String? ?? '',
    licenseUrl: json['licenseUrl'] as String? ?? '',
    sourceUrl: json['sourceUrl'] as String? ?? '',
    caption: json['caption'] as String? ?? '',
  );

  /// A stored file reference: `asset://`, `local://` or `https://`.
  final String ref;

  /// The backend's file id when the app stored it; empty for bundled photos.
  final String fileId;

  final String author;

  final String license;

  final String licenseUrl;

  final String sourceUrl;

  final String caption;

  bool get hasCredit => author.isNotEmpty || license.isNotEmpty;

  PlantPhoto copyWith({
    String? ref,
    String? fileId,
    String? author,
    String? license,
    String? licenseUrl,
    String? sourceUrl,
    String? caption,
  }) => PlantPhoto(
    ref: ref ?? this.ref,
    fileId: fileId ?? this.fileId,
    author: author ?? this.author,
    license: license ?? this.license,
    licenseUrl: licenseUrl ?? this.licenseUrl,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    caption: caption ?? this.caption,
  );

  Map<String, Object?> toJson() => {
    'ref': ref,
    'fileId': fileId,
    'author': author,
    'license': license,
    'licenseUrl': licenseUrl,
    'sourceUrl': sourceUrl,
    'caption': caption,
  };

  @override
  bool operator ==(Object other) =>
      other is PlantPhoto &&
      ref == other.ref &&
      fileId == other.fileId &&
      author == other.author &&
      license == other.license &&
      licenseUrl == other.licenseUrl &&
      sourceUrl == other.sourceUrl &&
      caption == other.caption;

  @override
  int get hashCode =>
      Object.hash(ref, fileId, author, license, licenseUrl, sourceUrl, caption);

  @override
  String toString() => 'PlantPhoto($ref)';
}

/// Where the plant's information comes from.
class PlantSource {
  const PlantSource({
    required this.title,
    this.id = '',
    this.kind = SourceKind.science,
    this.publisher = '',
    this.url = '',
    this.accessedOn = '',
  });

  factory PlantSource.fromJson(Map<String, Object?> json) => PlantSource(
    title: json['title'] as String,
    id: json['id'] as String? ?? '',
    kind: SourceKind.values.byName(
      json['kind'] as String? ?? SourceKind.science.name,
    ),
    publisher: json['publisher'] as String? ?? '',
    url: json['url'] as String? ?? '',
    accessedOn: json['accessedOn'] as String? ?? '',
  );

  /// How the plant's uses and preparations cite it: "s1".
  final String id;

  /// Whether it speaks for botany, popular use or science.
  final SourceKind kind;

  final String title;

  final String publisher;

  final String url;

  final String accessedOn;

  PlantSource copyWith({
    String? title,
    String? id,
    SourceKind? kind,
    String? publisher,
    String? url,
    String? accessedOn,
  }) => PlantSource(
    title: title ?? this.title,
    id: id ?? this.id,
    kind: kind ?? this.kind,
    publisher: publisher ?? this.publisher,
    url: url ?? this.url,
    accessedOn: accessedOn ?? this.accessedOn,
  );

  Map<String, Object?> toJson() => {
    'title': title,
    'id': id,
    'kind': kind.name,
    'publisher': publisher,
    'url': url,
    'accessedOn': accessedOn,
  };

  @override
  bool operator ==(Object other) =>
      other is PlantSource &&
      title == other.title &&
      id == other.id &&
      kind == other.kind &&
      publisher == other.publisher &&
      url == other.url &&
      accessedOn == other.accessedOn;

  @override
  int get hashCode => Object.hash(title, id, kind, publisher, url, accessedOn);

  @override
  String toString() => 'PlantSource($publisher: $title)';
}
