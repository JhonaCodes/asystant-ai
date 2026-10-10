import 'dart:convert';

import 'package:asystant_ai/src/mermaid/mermaid_direction.dart';
import 'package:asystant_ai/src/mermaid/mermaid_edge.dart';
import 'package:asystant_ai/src/mermaid/mermaid_flowchart.dart';
import 'package:asystant_ai/src/mermaid/mermaid_node.dart';
import 'package:asystant_ai/src/mermaid/mermaid_subgraph.dart';

/// Reads Mermaid flowchart source (`flowchart` or `graph`) into a
/// [MermaidFlowchart].
///
/// Returns null for anything outside the supported subset — another diagram
/// type, a malformed statement, an edge to a subgraph, a diagram over the
/// size limits — so the caller can show the source instead of a diagram that
/// says something different. It never throws.
///
/// Supported: the five directions; node shapes in [MermaidNodeShape], quoted
/// labels and `<br>`; links `-->`, `---`, `-.->`, `==>`, `~~~`, `<-->`,
/// `--o`, `--x` and longer variants, with `|label|` or `-- label -->`;
/// chains (`A --> B --> C`), `&` groups and `;` separators; nested
/// `subgraph … end`; `%%` comments. `classDef`, `class`, `style`,
/// `linkStyle`, `click`, `direction` and accessibility lines are ignored.
abstract final class MermaidFlowchartParser {
  /// Longest source read; a longer one is shown as code.
  static const int maxSourceLength = 20000;

  /// Most nodes laid out; beyond this the chat shows the source.
  static const int maxNodes = 150;

  static const int maxEdges = 300;

  static const int maxSubgraphDepth = 6;

  static MermaidFlowchart? parse(String source) {
    if (source.length > maxSourceLength) {
      return null;
    }
    final statements = _statements(source);
    if (statements.isEmpty) {
      return null;
    }
    final direction = _header(statements.first);
    if (direction == null) {
      return null;
    }
    final builder = _FlowchartBuilder(direction);
    for (final statement in statements.skip(1)) {
      if (!builder.add(statement)) {
        return null;
      }
    }
    return builder.build();
  }

  /// Non-empty statements: one per line, split at `;` outside brackets,
  /// quotes and `|labels|`. Comment lines and front matter are dropped.
  static List<String> _statements(String source) {
    final statements = <String>[];
    var inFrontMatter = false;
    var seenContent = false;
    for (final rawLine in const LineSplitter().convert(source)) {
      final line = rawLine.trim();
      if (line == '---' && (inFrontMatter || !seenContent)) {
        inFrontMatter = !inFrontMatter;
        seenContent = true;
        continue;
      }
      if (inFrontMatter || line.isEmpty || line.startsWith('%%')) {
        continue;
      }
      seenContent = true;
      var start = 0;
      var depth = 0;
      var quoted = false;
      var piped = false;
      for (var index = 0; index < line.length; index++) {
        final char = line[index];
        if (char == '"') {
          quoted = !quoted;
        } else if (quoted) {
          continue;
        } else if (char == '|' && depth == 0) {
          piped = !piped;
        } else if (piped) {
          continue;
        } else if ('[({'.contains(char)) {
          depth++;
        } else if (')]}'.contains(char)) {
          depth = depth > 0 ? depth - 1 : 0;
        } else if (char == ';' && depth == 0) {
          statements.add(line.substring(start, index));
          start = index + 1;
        }
      }
      statements.add(line.substring(start));
    }
    return [
      for (final statement in statements)
        if (statement.trim().isNotEmpty) statement.trim(),
    ];
  }

  static MermaidDirection? _header(String statement) {
    final words = statement.split(RegExp(r'\s+'));
    if (words.length > 2 ||
        !const {'flowchart', 'graph', 'flowchart-elk'}.contains(words.first)) {
      return null;
    }
    return words.length == 1
        ? MermaidDirection.topDown
        : MermaidDirection.fromKeyword(words.last);
  }
}

/// Collects nodes, edges and subgraphs while statements are read.
class _FlowchartBuilder {
  _FlowchartBuilder(this.direction);

  final MermaidDirection direction;

  final Map<String, MermaidNode> _nodes = {};

  final List<MermaidEdge> _edges = [];

  final List<MermaidSubgraph> _subgraphs = [];

  /// Ids of the subgraphs whose `end` has not been read yet, innermost last.
  final List<String> _open = [];

  static const Set<String> _ignored = {
    'classDef',
    'class',
    'style',
    'linkStyle',
    'click',
    'direction',
    'accTitle',
    'accDescr',
  };

  static final RegExp _keyword = RegExp(r'^[A-Za-z]+');

  static final RegExp _titled = RegExp(
    r'^([\p{L}\p{N}_][\p{L}\p{N}_.-]*)\s*\[(.*)\]$',
    unicode: true,
  );

  bool add(String statement) {
    final keyword = _keyword.stringMatch(statement) ?? '';
    final rest = statement.substring(keyword.length);
    return switch (keyword) {
      'subgraph' when rest.isEmpty || rest.startsWith(RegExp(r'\s')) =>
        _openSubgraph(rest.trim()),
      'end' when rest.trim().isEmpty => _closeSubgraph(),
      _ when _ignored.contains(keyword) && !rest.startsWith(RegExp(r'[\w-]')) =>
        true,
      _ => _chain(statement),
    };
  }

  bool _openSubgraph(String header) {
    if (header.isEmpty ||
        _open.length >= MermaidFlowchartParser.maxSubgraphDepth) {
      return false;
    }
    final titled = _titled.firstMatch(header);
    final quoted =
        header.length > 1 && header.startsWith('"') && header.endsWith('"');
    final id = switch ((titled, quoted)) {
      (final match?, _) => match.group(1)!,
      (null, true) => '#${_subgraphs.length + 1}',
      (null, false) => header,
    };
    if (_subgraphs.any((subgraph) => subgraph.id == id)) {
      return false;
    }
    _subgraphs.add(
      MermaidSubgraph(
        id: id,
        title: _LabelText.decode(titled?.group(2) ?? header),
        parent: _open.isEmpty ? null : _open.last,
      ),
    );
    _open.add(id);
    return true;
  }

  bool _closeSubgraph() {
    if (_open.isEmpty) {
      return false;
    }
    _open.removeLast();
    return true;
  }

  /// `group (link group)*`, where a group is `node (& node)*`.
  bool _chain(String statement) {
    final reader = _StatementReader(statement);
    var previous = _group(reader);
    if (previous == null) {
      return false;
    }
    while (!reader.atEnd()) {
      final link = reader.readLink();
      if (link == null) {
        return false;
      }
      final next = _group(reader);
      if (next == null) {
        return false;
      }
      for (final from in previous!) {
        for (final to in next) {
          _edges.add(
            MermaidEdge(
              from: from,
              to: to,
              label: link.label,
              stroke: link.stroke,
              head: link.head,
              tail: link.tail,
              length: link.length,
            ),
          );
        }
      }
      previous = next;
    }
    return _nodes.length <= MermaidFlowchartParser.maxNodes &&
        _edges.length <= MermaidFlowchartParser.maxEdges;
  }

  List<String>? _group(_StatementReader reader) {
    final ids = <String>[];
    do {
      final reference = reader.readNode();
      if (reference == null) {
        return null;
      }
      _declare(reference);
      ids.add(reference.id);
    } while (reader.readAmpersand());
    return ids;
  }

  void _declare(_NodeReference reference) {
    final known = _nodes[reference.id];
    final subgraph = known?.subgraph ?? (_open.isEmpty ? null : _open.last);
    _nodes[reference.id] = MermaidNode(
      id: reference.id,
      label: reference.label ?? known?.label ?? reference.id,
      shape: reference.shape ?? known?.shape ?? MermaidNodeShape.rectangle,
      subgraph: subgraph,
    );
  }

  MermaidFlowchart? build() {
    final subgraphIds = {for (final subgraph in _subgraphs) subgraph.id};
    // An edge to a subgraph's frame is not supported: show the source.
    if (_open.isNotEmpty ||
        _nodes.isEmpty ||
        _nodes.keys.any(subgraphIds.contains)) {
      return null;
    }
    return MermaidFlowchart(
      direction: direction,
      nodes: List.unmodifiable(_nodes.values),
      edges: List.unmodifiable(_edges),
      subgraphs: List.unmodifiable(_subgraphs),
    );
  }
}

/// A node as written in one place: id, and shape and label when bracketed.
typedef _NodeReference = ({String id, MermaidNodeShape? shape, String? label});

/// A link as written: stroke, ends, rank span and label.
typedef _Link = ({
  MermaidLinkStroke stroke,
  MermaidLinkEnd head,
  MermaidLinkEnd tail,
  int length,
  String label,
});

/// Reads the pieces of one statement left to right.
class _StatementReader {
  _StatementReader(this.text);

  final String text;

  int _position = 0;

  /// True once only spaces remain.
  bool atEnd() {
    _skipSpaces();
    return _position >= text.length;
  }

  static final RegExp _id = RegExp(
    r'[\p{L}\p{N}_](?:[\p{L}\p{N}_]|[-.](?=[\p{L}\p{N}_]))*',
    unicode: true,
  );

  static final RegExp _className = RegExp(r':::[\w-]+');

  /// Shapes by opening bracket, longest first; `[/` and `[\` close two ways.
  static const List<(String, String, MermaidNodeShape)> _shapes = [
    ('(((', ')))', MermaidNodeShape.doubleCircle),
    ('((', '))', MermaidNodeShape.circle),
    ('([', '])', MermaidNodeShape.stadium),
    ('[[', ']]', MermaidNodeShape.subroutine),
    ('[(', ')]', MermaidNodeShape.cylinder),
    ('{{', '}}', MermaidNodeShape.hexagon),
    ('[/', '/]', MermaidNodeShape.leanRight),
    ('[/', r'\]', MermaidNodeShape.trapezoid),
    (r'[\', r'\]', MermaidNodeShape.leanLeft),
    (r'[\', '/]', MermaidNodeShape.invertedTrapezoid),
    ('(', ')', MermaidNodeShape.rounded),
    ('[', ']', MermaidNodeShape.rectangle),
    ('{', '}', MermaidNodeShape.diamond),
    ('>', ']', MermaidNodeShape.asymmetric),
  ];

  /// Complete links: `-->`, `---`, `-.->`, `==>`, `~~~` and longer forms.
  static final RegExp _link = RegExp(
    r'-{2,}(?:>|[xo](?![\p{L}\p{N}_]))|-{3,}'
    r'|={2,}(?:>|[xo](?![\p{L}\p{N}_]))|={3,}'
    r'|-\.+-(?:>|[xo](?![\p{L}\p{N}_]))?'
    r'|~{3,}',
    unicode: true,
  );

  /// Where a `-- label -->` style link ends, by how it started.
  static final Map<String, RegExp> _labelEnds = {
    '--': RegExp(r'-{2,}(?:>|[xo](?![\p{L}\p{N}_]))|-{3,}', unicode: true),
    '==': RegExp(r'={2,}(?:>|[xo](?![\p{L}\p{N}_]))|={3,}', unicode: true),
    '-.': RegExp(r'\.+-(?:>|[xo](?![\p{L}\p{N}_]))?', unicode: true),
  };

  void _skipSpaces() {
    while (_position < text.length && text[_position].trim().isEmpty) {
      _position++;
    }
  }

  bool readAmpersand() {
    _skipSpaces();
    if (_position < text.length && text[_position] == '&') {
      _position++;
      return true;
    }
    return false;
  }

  _NodeReference? readNode() {
    _skipSpaces();
    final id = _id.matchAsPrefix(text, _position)?.group(0);
    if (id == null) {
      return null;
    }
    _position += id.length;
    final shaped = _readShape();
    if (!shaped.valid) {
      return null;
    }
    final className = _className.matchAsPrefix(text, _position);
    if (className != null) {
      _position = className.end;
    }
    return (id: id, shape: shaped.shape, label: shaped.label);
  }

  /// The bracketed shape after an id. Both are null when there is none;
  /// [valid] is false when a bracket opens but never closes.
  ({bool valid, MermaidNodeShape? shape, String? label}) _readShape() {
    // `A [text]` is accepted like `A[text]`; `>` must touch the id.
    final spaced = _skipSpacesFrom(_position);
    final start = spaced < text.length && '[({'.contains(text[spaced])
        ? spaced
        : _position;
    var opened = false;
    for (final (opener, closer, shape) in _shapes) {
      if (!text.startsWith(opener, start)) {
        continue;
      }
      opened = true;
      final label = _readLabel(start + opener.length, closer);
      if (label != null) {
        return (valid: true, shape: shape, label: label);
      }
    }
    return (valid: !opened, shape: null, label: null);
  }

  /// Text from [start] up to [closer], quoted or not; moves past the closer.
  String? _readLabel(int start, String closer) {
    final quoteStart = _skipSpacesFrom(start);
    if (quoteStart < text.length && text[quoteStart] == '"') {
      final quoteEnd = text.indexOf('"', quoteStart + 1);
      if (quoteEnd < 0) {
        return null;
      }
      final closerStart = _skipSpacesFrom(quoteEnd + 1);
      if (!text.startsWith(closer, closerStart)) {
        return null;
      }
      _position = closerStart + closer.length;
      return _LabelText.decode(text.substring(quoteStart + 1, quoteEnd));
    }
    // Unquoted text ends at the first closing bracket of its kind, and the
    // closer must sit right there: `[/a\] --> b[/c/]` is a trapezoid.
    final terminal = closer[closer.length - 1];
    final prefix = closer.indexOf(terminal);
    final end = text.indexOf(terminal, start + prefix);
    final closerStart = end - prefix;
    if (end < 0 ||
        closerStart < start ||
        !text.startsWith(closer, closerStart)) {
      return null;
    }
    _position = closerStart + closer.length;
    return _LabelText.decode(text.substring(start, closerStart));
  }

  int _skipSpacesFrom(int start) {
    var index = start;
    while (index < text.length && text[index].trim().isEmpty) {
      index++;
    }
    return index;
  }

  _Link? readLink() {
    _skipSpaces();
    var tail = MermaidLinkEnd.none;
    if (text.startsWith('<', _position)) {
      tail = MermaidLinkEnd.arrow;
      _position++;
    }
    final complete = _link.matchAsPrefix(text, _position);
    if (complete != null) {
      _position = complete.end;
      final label = _readPipeLabel();
      if (label == null) {
        return null;
      }
      return _describe(complete.group(0)!, tail, label);
    }
    for (final MapEntry(key: start, value: endPattern) in _labelEnds.entries) {
      if (!text.startsWith(start, _position)) {
        continue;
      }
      final labelStart = _position + start.length;
      final end = endPattern.allMatches(text, labelStart).firstOrNull;
      final label = end == null
          ? ''
          : _LabelText.decode(text.substring(labelStart, end.start));
      if (end == null || label.isEmpty) {
        return null;
      }
      _position = end.end;
      // `-. label .->` closes with `.->`: read as the link `-.->`.
      final closing = start == '-.' ? '-${end.group(0)}' : end.group(0)!;
      return _link.matchAsPrefix(closing)?.end == closing.length
          ? _describe(closing, tail, label)
          : null;
    }
    return null;
  }

  /// The `|label|` after a link: empty when there is none, null when open.
  String? _readPipeLabel() {
    final start = _skipSpacesFrom(_position);
    if (start >= text.length || text[start] != '|') {
      return '';
    }
    final end = text.indexOf('|', start + 1);
    final quoted = _skipSpacesFrom(start + 1);
    final quoteEnd = quoted < text.length && text[quoted] == '"'
        ? text.indexOf('"', quoted + 1)
        : -1;
    // A quoted label may contain `|`; the closing pipe follows its quote.
    final close = quoteEnd > 0 ? text.indexOf('|', quoteEnd + 1) : end;
    if (close < 0) {
      return null;
    }
    _position = close + 1;
    return _LabelText.decode(text.substring(start + 1, close));
  }

  /// What a complete link token such as `-.->` or `===` draws.
  static _Link _describe(String token, MermaidLinkEnd tail, String label) {
    final stroke = switch (token[0]) {
      '=' => MermaidLinkStroke.thick,
      '~' => MermaidLinkStroke.invisible,
      _ when token[1] == '.' => MermaidLinkStroke.dotted,
      _ => MermaidLinkStroke.solid,
    };
    final head = switch (token[token.length - 1]) {
      '>' => MermaidLinkEnd.arrow,
      'x' => MermaidLinkEnd.cross,
      'o' => MermaidLinkEnd.circle,
      _ => MermaidLinkEnd.none,
    };
    final body = head == MermaidLinkEnd.none ? token.length : token.length - 1;
    final length = switch (stroke) {
      // `-.->` spans one rank per dot.
      MermaidLinkStroke.dotted => body - 2,
      // `-->` and `==>` span one rank; `---` and `===` too.
      _ when head == MermaidLinkEnd.none => body - 2,
      _ => body - 1,
    };
    return (
      stroke: stroke,
      head: head,
      tail: tail,
      length: length < 1 ? 1 : length,
      label: label,
    );
  }
}

/// Turns label markup into display text: quotes, `<br>`, tags, entities.
abstract final class _LabelText {
  static final RegExp _lineBreak = RegExp(r'<br\s*/?>', caseSensitive: false);

  static final RegExp _tag = RegExp(r'</?[A-Za-z][^>]*>');

  static final RegExp _entity = RegExp(r'[#&](#?)(\w+);');

  static const Map<String, String> _named = {
    'quot': '"',
    'amp': '&',
    'lt': '<',
    'gt': '>',
    'apos': "'",
    'nbsp': ' ',
  };

  static String decode(String raw) {
    var text = raw.trim();
    for (final mark in const ['"', '`']) {
      if (text.length > 1 && text.startsWith(mark) && text.endsWith(mark)) {
        text = text.substring(1, text.length - 1);
      }
    }
    text = text
        .replaceAll(_lineBreak, '\n')
        .replaceAll(_tag, '')
        .replaceAllMapped(_entity, _entityText);
    return text.split('\n').map((line) => line.trim()).join('\n').trim();
  }

  static String _entityText(Match match) {
    final name = match.group(2)!;
    final code = int.tryParse(name);
    if (code != null && code > 0 && code <= 0x10FFFF) {
      return String.fromCharCode(code);
    }
    return _named[name] ?? match.group(0)!;
  }
}
