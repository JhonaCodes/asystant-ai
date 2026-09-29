part of '../ai.dart';

/// The app's vocabulary as the tools describe it to the model, and back:
/// what the person said, matched to a term by id, label or synonym.
abstract final class _Vocabulary {
  /// "gerd = Reflujo o acidez frecuente (agruras, acidez); …".
  static String of(TermKind kind) =>
      ReferenceService.notifier.termsOf(kind).map(_line).join('; ');

  static VocabularyTerm? match(TermKind kind, String text) =>
      ReferenceService.notifier.termMatching(kind, text);

  /// The first of [kinds] that [text] names.
  static VocabularyTerm? matchAny(List<TermKind> kinds, String text) => kinds
      .map((kind) => match(kind, text))
      .firstWhereOrNull((term) => term != null);

  /// The label of the [kind] term [text] names, or of any term it names
  /// ("gerd" sent as a symptom reads "Reflujo…"); otherwise its own words.
  static String labelFor(TermKind kind, String text) =>
      (match(kind, text) ?? matchAny(TermKind.values, text))?.label ?? text;

  static String _line(VocabularyTerm term) => switch (term.synonyms) {
    [] => '${term.id} = ${term.label}',
    final synonyms => '${term.id} = ${term.label} (${synonyms.join(', ')})',
  };
}
