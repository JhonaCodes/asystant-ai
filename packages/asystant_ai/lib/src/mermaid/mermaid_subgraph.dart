import 'package:flutter/foundation.dart';

/// A `subgraph … end` block: a titled group of nodes, possibly nested.
@immutable
class MermaidSubgraph {
  const MermaidSubgraph({required this.id, required this.title, this.parent});

  final String id;

  /// Shown at the top of the group's frame.
  final String title;

  /// Id of the enclosing subgraph, or null at the top level.
  final String? parent;

  MermaidSubgraph copyWith({String? id, String? title, String? parent}) =>
      MermaidSubgraph(
        id: id ?? this.id,
        title: title ?? this.title,
        parent: parent ?? this.parent,
      );

  @override
  bool operator ==(Object other) =>
      other is MermaidSubgraph &&
      id == other.id &&
      title == other.title &&
      parent == other.parent;

  @override
  int get hashCode => Object.hash(id, title, parent);

  @override
  String toString() => 'MermaidSubgraph($id, "$title", parent: $parent)';
}
