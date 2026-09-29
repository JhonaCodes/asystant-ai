import 'package:asystant_core/src/model/assistant_value.dart';

/// What to look for in a [KnowledgeRetriever].
///
/// A value object rather than positional arguments, so a retriever keeps
/// compiling when a later version adds a field.
class KnowledgeQuery extends AssistantValue {
  const KnowledgeQuery({
    required this.text,
    this.collection,
    this.tags = const [],
    this.limit = 5,
  });

  /// Free text, in any language the documents are written in.
  final String text;

  /// Only documents of this collection; every collection when null.
  final String? collection;

  /// Only documents that carry every one of these tags.
  final List<String> tags;

  /// The most hits to return. Retrievers clamp it to their own bounds.
  final int limit;

  KnowledgeQuery copyWith({
    String? text,
    String? collection,
    bool clearCollection = false,
    List<String>? tags,
    int? limit,
  }) => KnowledgeQuery(
    text: text ?? this.text,
    collection: clearCollection ? null : collection ?? this.collection,
    tags: List.unmodifiable(tags ?? this.tags),
    limit: limit ?? this.limit,
  );

  factory KnowledgeQuery.fromJson(Map<String, Object?> json) => KnowledgeQuery(
    text: json['text'] as String,
    collection: json['collection'] as String?,
    tags: List.unmodifiable(
      (json['tags'] as List<Object?>? ?? const []).cast<String>(),
    ),
    limit: json['limit'] as int? ?? 5,
  );

  @override
  Map<String, Object?> toJson() => {
    'text': text,
    if (collection != null) 'collection': collection,
    if (tags.isNotEmpty) 'tags': tags,
    'limit': limit,
  };
}
