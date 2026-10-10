import 'package:flutter/foundation.dart';

import 'package:asystant_ai/src/mermaid/mermaid_direction.dart';
import 'package:asystant_ai/src/mermaid/mermaid_edge.dart';
import 'package:asystant_ai/src/mermaid/mermaid_node.dart';
import 'package:asystant_ai/src/mermaid/mermaid_subgraph.dart';

/// A parsed Mermaid flowchart, independent of how it is drawn.
///
/// Derived from the message text each time it is shown; never stored.
@immutable
class MermaidFlowchart {
  const MermaidFlowchart({
    required this.direction,
    required this.nodes,
    required this.edges,
    this.subgraphs = const [],
  });

  final MermaidDirection direction;

  /// In the order each node first appears in the source.
  final List<MermaidNode> nodes;

  /// In source order.
  final List<MermaidEdge> edges;

  /// In source order: a parent always comes before its children.
  final List<MermaidSubgraph> subgraphs;

  MermaidFlowchart copyWith({
    MermaidDirection? direction,
    List<MermaidNode>? nodes,
    List<MermaidEdge>? edges,
    List<MermaidSubgraph>? subgraphs,
  }) => MermaidFlowchart(
    direction: direction ?? this.direction,
    nodes: nodes ?? this.nodes,
    edges: edges ?? this.edges,
    subgraphs: subgraphs ?? this.subgraphs,
  );

  @override
  bool operator ==(Object other) =>
      other is MermaidFlowchart &&
      direction == other.direction &&
      listEquals(nodes, other.nodes) &&
      listEquals(edges, other.edges) &&
      listEquals(subgraphs, other.subgraphs);

  @override
  int get hashCode => Object.hash(
    direction,
    Object.hashAll(nodes),
    Object.hashAll(edges),
    Object.hashAll(subgraphs),
  );
}
