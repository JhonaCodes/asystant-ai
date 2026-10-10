import 'package:flutter/foundation.dart';

/// The outline Mermaid gives a node, from the brackets around its text.
enum MermaidNodeShape {
  /// `A[text]`
  rectangle,

  /// `A(text)`
  rounded,

  /// `A([text])`
  stadium,

  /// `A[[text]]`
  subroutine,

  /// `A[(text)]`
  cylinder,

  /// `A((text))`
  circle,

  /// `A(((text)))`
  doubleCircle,

  /// `A{text}`, a decision.
  diamond,

  /// `A{{text}}`
  hexagon,

  /// `A[/text/]`
  leanRight,

  /// `A[\text\]`
  leanLeft,

  /// `A[/text\]`, wider at the bottom.
  trapezoid,

  /// `A[\text/]`, wider at the top.
  invertedTrapezoid,

  /// `A>text]`, a flag notched on the left.
  asymmetric,
}

/// One step of a flowchart: its id, the text it shows and its outline.
@immutable
class MermaidNode {
  const MermaidNode({
    required this.id,
    required this.label,
    this.shape = MermaidNodeShape.rectangle,
    this.subgraph,
  });

  /// How edges refer to the node.
  final String id;

  /// Text shown inside; `\n` marks a line break written as `<br>`.
  final String label;

  final MermaidNodeShape shape;

  /// Id of the innermost subgraph the node belongs to, or null.
  final String? subgraph;

  MermaidNode copyWith({
    String? id,
    String? label,
    MermaidNodeShape? shape,
    String? subgraph,
  }) => MermaidNode(
    id: id ?? this.id,
    label: label ?? this.label,
    shape: shape ?? this.shape,
    subgraph: subgraph ?? this.subgraph,
  );

  @override
  bool operator ==(Object other) =>
      other is MermaidNode &&
      id == other.id &&
      label == other.label &&
      shape == other.shape &&
      subgraph == other.subgraph;

  @override
  int get hashCode => Object.hash(id, label, shape, subgraph);

  @override
  String toString() => 'MermaidNode($id, $shape, "$label")';
}
