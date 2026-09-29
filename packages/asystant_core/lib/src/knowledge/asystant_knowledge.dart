import 'dart:math' as math;

import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/knowledge/knowledge_document.dart';
import 'package:asystant_core/src/knowledge/knowledge_hit.dart';
import 'package:asystant_core/src/knowledge/knowledge_query.dart';
import 'package:asystant_core/src/knowledge/knowledge_retriever.dart';
import 'package:asystant_core/src/knowledge/knowledge_text.dart';
import 'package:asystant_core/src/model/assistant_failure.dart';

/// A local, in-memory index of the application's documents, searched with
/// BM25: the lexical ranking of classic search engines.
///
/// Why lexical and not embeddings: it needs no model, no service and no
/// dependency, runs the same on mobile, web and desktop, is deterministic
/// (the same documents and query always give the same order, which makes it
/// testable), and indexes a few thousand documents in milliseconds. It finds
/// the words of the query, including accents, plurals and gender folded for
/// Spanish and English, but not their synonyms. A semantic retriever can
/// replace it later through [KnowledgeRetriever] without changing the apps
/// or the search tool.
///
/// Documents are added, replaced and removed by id with [put], [putAll] and
/// [remove]. [toJson] and [AsystantKnowledge.fromJson] save and restore the
/// documents wherever the application keeps data; the index is rebuilt on
/// restore, so the saved form is only the documents.
///
/// ```dart
/// final knowledge = AsystantKnowledge()
///   ..put(const KnowledgeDocument(
///     id: 'care-orchid',
///     title: 'Orchid watering',
///     collection: 'guides',
///     text: 'Water orchids once a week, in the morning...',
///   ));
/// ```
class AsystantKnowledge extends KnowledgeRetriever {
  AsystantKnowledge({
    Iterable<KnowledgeDocument> documents = const [],
    this.snippetLength = defaultSnippetLength,
  }) : assert(snippetLength >= 40, 'snippetLength must be at least 40') {
    putAll(documents);
  }

  /// Restores an index saved with [toJson].
  factory AsystantKnowledge.fromJson(
    Map<String, Object?> json, {
    int snippetLength = defaultSnippetLength,
  }) => AsystantKnowledge(
    documents: (json['documents'] as List<Object?>).map(
      (document) =>
          KnowledgeDocument.fromJson(document as Map<String, Object?>),
    ),
    snippetLength: snippetLength,
  );

  /// Characters of the passage returned with each hit.
  static const int defaultSnippetLength = 320;

  /// The most hits one search returns, whatever the query's limit.
  static const int maxLimit = 50;

  /// The version of the [toJson] format.
  static const int formatVersion = 1;

  /// BM25 term-frequency saturation.
  static const double _k1 = 1.2;

  /// BM25 length normalization.
  static const double _b = 0.75;

  /// A title word counts as this many body words.
  static const int _titleWeight = 2;

  /// What a term found by prefix, not exactly, weighs.
  static const double _prefixWeight = 0.5;

  /// The most indexed terms one query term expands to by prefix.
  static const int _maxExpansions = 16;

  /// The shortest query term that also matches by prefix.
  static const int _minPrefix = 4;

  final int snippetLength;

  final Map<String, _Entry> _entries = {};

  /// term → document id → occurrences.
  final Map<String, Map<String, int>> _postings = {};

  int _totalLength = 0;

  /// The documents, in the order they were added.
  List<KnowledgeDocument> get documents =>
      List.unmodifiable(_entries.values.map((entry) => entry.document));

  int get length => _entries.length;

  bool get isEmpty => _entries.isEmpty;

  /// The document with [id], if any.
  KnowledgeDocument? document(String id) => _entries[id]?.document;

  @override
  List<String> get collections {
    final names = <String>{
      for (final entry in _entries.values)
        if (entry.document.collection case final String name) name,
    };
    return List.unmodifiable(names.toList()..sort());
  }

  /// Adds [document], replacing the one with the same id.
  ///
  /// Throws an [ArgumentError] when the id is empty.
  void put(KnowledgeDocument document) {
    if (document.id.trim().isEmpty) {
      throw ArgumentError.value(document.id, 'document.id', 'is empty');
    }
    remove(document.id);
    final frequencies = <String, int>{};
    _count(frequencies, document.title, _titleWeight);
    for (final tag in document.tags) {
      _count(frequencies, tag, 1);
    }
    _count(frequencies, document.text, 1);
    final length = frequencies.values.fold(0, (sum, count) => sum + count);
    _entries[document.id] = _Entry(
      document: document,
      frequencies: frequencies,
      length: length,
      tags: {for (final tag in document.tags) KnowledgeText.normalize(tag)},
    );
    _totalLength += length;
    for (final MapEntry(key: term, value: count) in frequencies.entries) {
      (_postings[term] ??= {})[document.id] = count;
    }
  }

  void putAll(Iterable<KnowledgeDocument> documents) {
    for (final document in documents) {
      put(document);
    }
  }

  /// Removes the document with [id]; false when there was none.
  bool remove(String id) {
    final entry = _entries.remove(id);
    if (entry == null) {
      return false;
    }
    _totalLength -= entry.length;
    for (final term in entry.frequencies.keys) {
      final postings = _postings[term];
      postings?.remove(id);
      if (postings != null && postings.isEmpty) {
        _postings.remove(term);
      }
    }
    return true;
  }

  void clear() {
    _entries.clear();
    _postings.clear();
    _totalLength = 0;
  }

  /// Ranks the documents for [query] (see [KnowledgeRetriever.search]).
  /// Always `Ok`: an empty list when the query has no searchable word or
  /// nothing matches.
  @override
  Future<Result<List<KnowledgeHit>, AssistantFailure>> search(
    KnowledgeQuery query,
  ) async => Ok(rank(query));

  /// The synchronous form of [search].
  List<KnowledgeHit> rank(KnowledgeQuery query) {
    final weights = _queryWeights(query.text);
    if (weights.isEmpty || _entries.isEmpty) {
      return const [];
    }
    final collection = query.collection?.trim();
    final tags = {for (final tag in query.tags) KnowledgeText.normalize(tag)};
    final count = _entries.length;
    final averageLength = _totalLength / count;
    final scores = <String, double>{};
    final idf = <String, double>{};
    for (final MapEntry(key: term, value: weight) in weights.entries) {
      final postings = _postings[term] ?? const <String, int>{};
      final termIdf = math.log(
        1 + (count - postings.length + 0.5) / (postings.length + 0.5),
      );
      idf[term] = termIdf * weight;
      for (final MapEntry(key: id, value: frequency) in postings.entries) {
        final entry = _entries[id];
        if (entry == null || !entry.matches(collection, tags)) {
          continue;
        }
        final norm = _k1 * (1 - _b + _b * entry.length / averageLength);
        scores[id] =
            (scores[id] ?? 0) +
            termIdf * weight * frequency * (_k1 + 1) / (frequency + norm);
      }
    }
    final ranked = scores.entries.toList()
      ..sort(
        (a, b) => b.value != a.value
            ? b.value.compareTo(a.value)
            : a.key.compareTo(b.key),
      );
    return List.unmodifiable([
      for (final MapEntry(key: id, value: score) in ranked.take(
        query.limit.clamp(1, maxLimit),
      ))
        if (_entries[id] case final _Entry entry)
          KnowledgeHit(
            id: id,
            title: entry.document.title,
            collection: entry.document.collection,
            score: score,
            snippet: _snippet(entry.document.text, idf),
            tags: entry.document.tags,
            metadata: entry.document.metadata,
          ),
    ]);
  }

  /// Saves the documents; see [AsystantKnowledge.fromJson].
  Map<String, Object?> toJson() => {
    'version': formatVersion,
    'documents': [for (final entry in _entries.values) entry.document.toJson()],
  };

  static void _count(Map<String, int> frequencies, String text, int weight) {
    for (final term in KnowledgeText.terms(text)) {
      frequencies[term] = (frequencies[term] ?? 0) + weight;
    }
  }

  /// The indexed terms [text] searches for, each with its weight: 1 for an
  /// exact term, [_prefixWeight] for one it only starts.
  Map<String, double> _queryWeights(String text) {
    final weights = <String, double>{};
    for (final term in KnowledgeText.terms(text).toSet()) {
      if (_postings.containsKey(term)) {
        weights[term] = 1;
      }
      if (term.length < _minPrefix) {
        continue;
      }
      final expansions =
          _postings.keys
              .where((indexed) => indexed != term && indexed.startsWith(term))
              .toList()
            ..sort((a, b) {
              final byCount =
                  (_postings[b]?.length ?? 0) - (_postings[a]?.length ?? 0);
              return byCount != 0 ? byCount : a.compareTo(b);
            });
      for (final indexed in expansions.take(_maxExpansions)) {
        weights[indexed] = math.max(weights[indexed] ?? 0, _prefixWeight);
      }
    }
    return weights;
  }

  /// The passage of [text], at most [snippetLength] characters, that covers
  /// the most weight of distinct query terms; the start of the text when no
  /// term is in it.
  String _snippet(String text, Map<String, double> weights) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= snippetLength) {
      return compact;
    }
    final tokens = KnowledgeText.tokens(compact);
    final counts = <String, int>{};
    var covered = 0.0;
    var matches = 0;
    var best = 0.0;
    var bestLeft = -1;
    var bestRight = -1;
    var left = 0;
    for (var right = 0; right < tokens.length; right++) {
      final entering = tokens[right].term;
      if (weights[entering] case final double weight) {
        final seen = counts[entering] ?? 0;
        counts[entering] = seen + 1;
        matches++;
        if (seen == 0) {
          covered += weight;
        }
      }
      while (tokens[right].end - tokens[left].start > snippetLength) {
        final leaving = tokens[left].term;
        if (weights[leaving] case final double weight) {
          final seen = (counts[leaving] ?? 1) - 1;
          counts[leaving] = seen;
          matches--;
          if (seen == 0) {
            covered -= weight;
          }
        }
        left++;
      }
      final score = covered + matches * 0.01;
      if (score > best + 1e-9) {
        best = score;
        bestLeft = left;
        bestRight = right;
      }
    }
    var start = 0;
    if (bestLeft >= 0) {
      var first = bestLeft;
      while (!weights.containsKey(tokens[first].term)) {
        first++;
      }
      var last = bestRight;
      while (!weights.containsKey(tokens[last].term)) {
        last--;
      }
      final firstStart = tokens[first].start;
      final slack = snippetLength - (tokens[last].end - firstStart);
      start = math.max(0, firstStart - slack ~/ 2);
      final sentence = compact
          .substring(start, firstStart)
          .lastIndexOf(RegExp(r'[.!?;:]\s'));
      if (sentence >= 0) {
        start += sentence + 2;
      } else {
        while (start > 0 &&
            start < firstStart &&
            KnowledgeText.isWordUnit(compact.codeUnitAt(start - 1))) {
          start++;
        }
      }
    }
    var end = math.min(compact.length, start + snippetLength);
    if (end < compact.length) {
      final space = compact.lastIndexOf(' ', end);
      if (space > start + snippetLength ~/ 2) {
        end = space;
      }
    }
    final passage = compact.substring(start, end).trim();
    return '${start > 0 ? '…' : ''}$passage${end < compact.length ? '…' : ''}';
  }
}

/// One indexed document with its term counts.
final class _Entry {
  const _Entry({
    required this.document,
    required this.frequencies,
    required this.length,
    required this.tags,
  });

  final KnowledgeDocument document;

  final Map<String, int> frequencies;

  final int length;

  /// Normalized tags, for filtering.
  final Set<String> tags;

  bool matches(String? collection, Set<String> required) =>
      (collection == null ||
          collection.isEmpty ||
          document.collection == collection) &&
      tags.containsAll(required);
}
