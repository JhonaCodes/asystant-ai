import 'package:asystant_core/src/model/assistant_value.dart';

/// One document of the application's own domain, searchable by the
/// assistant through a [KnowledgeRetriever] such as [AsystantKnowledge].
///
/// [id] is stable and chosen by the application: adding a document with an
/// id that already exists replaces it. [collection] groups documents of one
/// kind (`faq`, `species`, `policies`) so a search can be narrowed to it;
/// [tags] are free labels for the same purpose. [metadata] holds simple
/// values the application wants back with a hit, such as a route or a
/// record id; it is not searched and not sent to the model.
class KnowledgeDocument extends AssistantValue {
  const KnowledgeDocument({
    required this.id,
    required this.title,
    required this.text,
    this.collection,
    this.tags = const [],
    this.metadata = const {},
  });

  final String id;

  final String title;

  /// The searchable body. Plain text or Markdown; a hit returns only the
  /// passage that matches, never the whole text.
  final String text;

  final String? collection;

  final List<String> tags;

  final Map<String, String> metadata;

  KnowledgeDocument copyWith({
    String? id,
    String? title,
    String? text,
    String? collection,
    bool clearCollection = false,
    List<String>? tags,
    Map<String, String>? metadata,
  }) => KnowledgeDocument(
    id: id ?? this.id,
    title: title ?? this.title,
    text: text ?? this.text,
    collection: clearCollection ? null : collection ?? this.collection,
    tags: List.unmodifiable(tags ?? this.tags),
    metadata: Map.unmodifiable(metadata ?? this.metadata),
  );

  factory KnowledgeDocument.fromJson(Map<String, Object?> json) =>
      KnowledgeDocument(
        id: json['id'] as String,
        title: json['title'] as String,
        text: json['text'] as String,
        collection: json['collection'] as String?,
        tags: List.unmodifiable(
          (json['tags'] as List<Object?>? ?? const []).cast<String>(),
        ),
        metadata: Map.unmodifiable(
          (json['metadata'] as Map<String, Object?>? ?? const {}).map(
            (key, value) => MapEntry(key, value as String),
          ),
        ),
      );

  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'text': text,
    if (collection != null) 'collection': collection,
    if (tags.isNotEmpty) 'tags': tags,
    if (metadata.isNotEmpty) 'metadata': metadata,
  };
}
