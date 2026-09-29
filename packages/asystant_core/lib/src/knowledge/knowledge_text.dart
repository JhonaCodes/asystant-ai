/// One searchable word of a text: where it is and the term it indexes as.
typedef KnowledgeToken = ({int start, int end, String term});

/// The text analysis shared by indexing and searching, for Spanish and
/// English: lower case, accents folded (`á` → `a`, `ñ` → `n`), common words
/// of both languages dropped, and a light stemmer that joins singular and
/// plural, masculine and feminine (`orquídeas`, `orquidea` → `orquide`;
/// `luces`, `luz` → `luc`; `cities`, `city` → `citi`).
///
/// Deliberately small and rule-based: no dictionary, no model, the same
/// output on every platform. It does not conjugate verbs; a query term of
/// four letters or more also matches the indexed terms it starts, which
/// covers most other endings.
abstract final class KnowledgeText {
  /// The terms of [text], in order, repeated as often as they occur.
  static List<String> terms(String text) => [
    for (final token in tokens(text)) token.term,
  ];

  /// The words of [text] with their offsets, stop words excluded.
  static List<KnowledgeToken> tokens(String text) {
    final result = <KnowledgeToken>[];
    final word = <int>[];
    var start = -1;
    for (var index = 0; index <= text.length; index++) {
      final folded = index < text.length ? _fold(text.codeUnitAt(index)) : -1;
      if (folded >= 0) {
        if (start < 0) {
          start = index;
        }
        word.add(folded);
        continue;
      }
      if (start >= 0) {
        final raw = String.fromCharCodes(word);
        if (_keeps(raw)) {
          result.add((start: start, end: index, term: stem(raw)));
        }
        word.clear();
        start = -1;
      }
    }
    return result;
  }

  /// Lower case with accents folded; separators become spaces.
  static String normalize(String text) => String.fromCharCodes([
    for (final unit in text.codeUnits)
      switch (_fold(unit)) {
        -1 => 0x20,
        final folded => folded,
      },
  ]).trim();

  /// Whether [unit] belongs to a word.
  static bool isWordUnit(int unit) => _fold(unit) >= 0;

  /// Reduces a normalized word to the term it indexes as.
  static String stem(String word) {
    if (word.contains(_digit)) {
      return word;
    }
    var term = word;
    if (term.length > 3) {
      if (term.length > 4 && term.endsWith('ies')) {
        term = '${term.substring(0, term.length - 3)}i';
      } else if (term.length > 4 && term.endsWith('es')) {
        term = term.substring(0, term.length - 2);
      } else if (term.endsWith('s') &&
          !term.endsWith('ss') &&
          !term.endsWith('us') &&
          !term.endsWith('is')) {
        term = term.substring(0, term.length - 1);
      }
      if (term.length > 3 && 'aeo'.contains(term[term.length - 1])) {
        term = term.substring(0, term.length - 1);
      }
      if (term.length > 3 && term.endsWith('y')) {
        term = '${term.substring(0, term.length - 1)}i';
      }
    }
    if (term.length > 2 && term.endsWith('z')) {
      term = '${term.substring(0, term.length - 1)}c';
    }
    return term;
  }

  static final RegExp _digit = RegExp('[0-9]');

  static bool _keeps(String word) =>
      (word.length > 1 || word.contains(_digit)) && !_stopWords.contains(word);

  /// The lower-case, accent-free form of one UTF-16 unit, or -1 for a
  /// separator.
  static int _fold(int unit) {
    if (unit >= 0x30 && unit <= 0x39 || unit >= 0x61 && unit <= 0x7a) {
      return unit;
    }
    if (unit >= 0x41 && unit <= 0x5a) {
      return unit + 0x20;
    }
    if (unit < 0xc0 ||
        unit == 0xd7 ||
        unit == 0xf7 ||
        unit >= 0x2000 && unit <= 0x2bff ||
        unit >= 0x3000 && unit <= 0x303f ||
        unit >= 0xd800 && unit <= 0xdfff ||
        unit >= 0xfe00 && unit <= 0xfe0f) {
      return -1;
    }
    final lower = String.fromCharCode(unit).toLowerCase();
    if (lower.length != 1) {
      return -1;
    }
    return _accents[lower] ?? lower.codeUnitAt(0);
  }

  /// Accented letters and the letter each folds to.
  static final Map<String, int> _accents = {
    for (final (letters, base) in const [
      ('àáâãäå', 'a'),
      ('èéêë', 'e'),
      ('ìíîï', 'i'),
      ('òóôõö', 'o'),
      ('ùúûü', 'u'),
      ('ñ', 'n'),
      ('ç', 'c'),
      ('ýÿ', 'y'),
    ])
      for (final letter in letters.split('')) letter: base.codeUnitAt(0),
  };

  /// Frequent Spanish and English words that say nothing about the topic,
  /// already normalized.
  static const Set<String> _stopWords = {
    // Spanish
    'al', 'algo', 'algun', 'alguna', 'algunas', 'alguno', 'algunos',
    'ante', 'antes', 'como', 'con', 'contra', 'cual', 'cuando', 'de',
    'del', 'desde', 'donde', 'durante', 'el', 'ella', 'ellas', 'ellos',
    'en', 'entre', 'era', 'es', 'esa', 'esas', 'ese', 'eso', 'esos',
    'esta', 'estan', 'estas', 'este', 'esto', 'estos', 'fue', 'ha',
    'han', 'hay', 'hasta', 'la', 'las', 'le', 'les', 'lo', 'los', 'mas',
    'me', 'mi', 'mis', 'mucho', 'muchos', 'muy', 'ni', 'no', 'nos',
    'nosotros', 'nuestra', 'nuestro', 'otra', 'otras', 'otro', 'otros',
    'para', 'pero', 'poco', 'por', 'porque', 'que', 'quien', 'quienes',
    'se', 'sea', 'ser', 'si', 'sin', 'sobre', 'son', 'su', 'sus',
    'tambien', 'te', 'ti', 'todo', 'todos', 'tu', 'tus', 'un', 'una',
    'unas', 'uno', 'unos', 'usted', 'ustedes', 'ya', 'yo',
    // English
    'about', 'after', 'all', 'am', 'an', 'and', 'any', 'are', 'as', 'at',
    'be', 'been', 'before', 'being', 'both', 'but', 'by', 'can', 'did',
    'do', 'does', 'each', 'for', 'from', 'had', 'has', 'have', 'he',
    'her', 'here', 'him', 'his', 'how', 'if', 'in', 'into', 'is', 'it',
    'its', 'just', 'more', 'most', 'my', 'nor', 'not', 'of', 'off', 'on',
    'only', 'or', 'other', 'our', 'out', 'over', 'own', 'same', 'she',
    'should', 'so', 'some', 'such', 'than', 'that', 'the', 'their',
    'them', 'then', 'there', 'these', 'they', 'this', 'those', 'through',
    'to', 'too', 'under', 'up', 'very', 'was', 'we', 'were', 'what',
    'when', 'where', 'which', 'who', 'whom', 'why', 'will', 'with',
    'would', 'you', 'your',
  };
}
