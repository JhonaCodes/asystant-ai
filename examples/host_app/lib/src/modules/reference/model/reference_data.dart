import 'package:collection/collection.dart';

import 'package:host_app/src/modules/reference/model/red_flag_rule.dart';
import 'package:host_app/src/modules/reference/model/term_kind.dart';
import 'package:host_app/src/modules/reference/model/vocabulary_term.dart';
import 'package:host_app/src/shared/shared.dart';

/// The shared vocabulary and the warning-sign rules.
class ReferenceData {
  const ReferenceData({
    this.version = 0,
    this.terms = const [],
    this.redFlags = const [],
  });

  factory ReferenceData.fromJson(Map<String, Object?> json) => ReferenceData(
    version: json['version'] as int? ?? 0,
    terms: List.unmodifiable(
      (json['terms'] as List<Object?>? ?? const []).map(
        (term) => VocabularyTerm.fromJson(term as Map<String, Object?>),
      ),
    ),
    redFlags: List.unmodifiable(
      (json['redFlags'] as List<Object?>? ?? const []).map(
        (rule) => RedFlagRule.fromJson(rule as Map<String, Object?>),
      ),
    ),
  );

  final int version;

  final List<VocabularyTerm> terms;

  final List<RedFlagRule> redFlags;

  List<VocabularyTerm> termsOf(TermKind kind) =>
      terms.where((term) => term.kind == kind).toList();

  VocabularyTerm? termFor(String tag) =>
      terms.firstWhereOrNull((term) => term.id == tag);

  /// The [kind] term that [text] names by its id, label or a synonym,
  /// ignoring case and accents: "agruras" is `gerd`.
  VocabularyTerm? termMatching(TermKind kind, String text) {
    final key = text.searchKey;
    return termsOf(kind).firstWhereOrNull(
      (term) => [
        term.id,
        term.label,
        ...term.synonyms,
      ].any((name) => name.searchKey == key),
    );
  }

  /// The readable name of [tag], or the tag itself.
  String labelOf(String tag) => termFor(tag)?.label ?? tag;

  RedFlagRule? ruleFor(String id) =>
      redFlags.firstWhereOrNull((rule) => rule.id == id);

  ReferenceData copyWith({
    int? version,
    List<VocabularyTerm>? terms,
    List<RedFlagRule>? redFlags,
  }) => ReferenceData(
    version: version ?? this.version,
    terms: List.unmodifiable(terms ?? this.terms),
    redFlags: List.unmodifiable(redFlags ?? this.redFlags),
  );

  Map<String, Object?> toJson() => {
    'version': version,
    'terms': terms.map((term) => term.toJson()).toList(),
    'redFlags': redFlags.map((rule) => rule.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      other is ReferenceData &&
      version == other.version &&
      const ListEquality<VocabularyTerm>().equals(terms, other.terms) &&
      const ListEquality<RedFlagRule>().equals(redFlags, other.redFlags);

  @override
  int get hashCode =>
      Object.hash(version, Object.hashAll(terms), Object.hashAll(redFlags));

  @override
  String toString() =>
      'ReferenceData(v$version, ${terms.length} terms, ${redFlags.length} rules)';
}
