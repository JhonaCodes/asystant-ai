import 'package:asystant_core/src/model/assistant_value.dart';

/// One document found by a [KnowledgeRetriever], with the passage that
/// matched instead of the whole text, to keep the model's context small.
class KnowledgeHit extends AssistantValue {
  const KnowledgeHit({
    required this.id,
    required this.title,
    required this.score,
    required this.snippet,
    this.collection,
    this.tags = const [],
    this.metadata = const {},
  });

  /// The [KnowledgeDocument.id] of the document.
  final String id;

  final String title;

  final String? collection;

  /// Relevance, higher is better. Comparable within one search only: its
  /// scale depends on the retriever and the collection.
  final double score;

  /// The most relevant passage, with `…` where the text was cut.
  final String snippet;

  final List<String> tags;

  /// The document's metadata, for the host; the built-in search tool does
  /// not send it to the model.
  final Map<String, String> metadata;

  KnowledgeHit copyWith({
    String? id,
    String? title,
    String? collection,
    bool clearCollection = false,
    double? score,
    String? snippet,
    List<String>? tags,
    Map<String, String>? metadata,
  }) => KnowledgeHit(
    id: id ?? this.id,
    title: title ?? this.title,
    collection: clearCollection ? null : collection ?? this.collection,
    score: score ?? this.score,
    snippet: snippet ?? this.snippet,
    tags: List.unmodifiable(tags ?? this.tags),
    metadata: Map.unmodifiable(metadata ?? this.metadata),
  );

  factory KnowledgeHit.fromJson(Map<String, Object?> json) => KnowledgeHit(
    id: json['id'] as String,
    title: json['title'] as String,
    collection: json['collection'] as String?,
    score: (json['score'] as num).toDouble(),
    snippet: json['snippet'] as String,
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
    if (collection != null) 'collection': collection,
    'score': score,
    'snippet': snippet,
    if (tags.isNotEmpty) 'tags': tags,
    if (metadata.isNotEmpty) 'metadata': metadata,
  };
}
