import 'package:flutter/foundation.dart';

/// How a link is stroked: `-->` solid, `-.->` dotted, `==>` thick and `~~~`
/// invisible (it only places its nodes).
enum MermaidLinkStroke { solid, dotted, thick, invisible }

/// What a link draws where it meets a node.
enum MermaidLinkEnd {
  none,

  /// `-->`
  arrow,

  /// `--o`
  circle,

  /// `--x`
  cross,
}

/// A link between two nodes, in the direction it was written.
@immutable
class MermaidEdge {
  const MermaidEdge({
    required this.from,
    required this.to,
    this.label = '',
    this.stroke = MermaidLinkStroke.solid,
    this.head = MermaidLinkEnd.arrow,
    this.tail = MermaidLinkEnd.none,
    this.length = 1,
  });

  /// Id of the node the link starts at.
  final String from;

  /// Id of the node the link points to.
  final String to;

  /// Text on the link (`-->|text|` or `-- text -->`); empty when none.
  final String label;

  final MermaidLinkStroke stroke;

  /// Drawn where the link meets [to].
  final MermaidLinkEnd head;

  /// Drawn where the link meets [from]: an arrow for `<-->`.
  final MermaidLinkEnd tail;

  /// Minimum number of ranks the link spans: `-->` is 1, `--->` is 2.
  final int length;

  MermaidEdge copyWith({
    String? from,
    String? to,
    String? label,
    MermaidLinkStroke? stroke,
    MermaidLinkEnd? head,
    MermaidLinkEnd? tail,
    int? length,
  }) => MermaidEdge(
    from: from ?? this.from,
    to: to ?? this.to,
    label: label ?? this.label,
    stroke: stroke ?? this.stroke,
    head: head ?? this.head,
    tail: tail ?? this.tail,
    length: length ?? this.length,
  );

  @override
  bool operator ==(Object other) =>
      other is MermaidEdge &&
      from == other.from &&
      to == other.to &&
      label == other.label &&
      stroke == other.stroke &&
      head == other.head &&
      tail == other.tail &&
      length == other.length;

  @override
  int get hashCode => Object.hash(from, to, label, stroke, head, tail, length);

  @override
  String toString() => 'MermaidEdge($from -> $to, "$label", $stroke)';
}
