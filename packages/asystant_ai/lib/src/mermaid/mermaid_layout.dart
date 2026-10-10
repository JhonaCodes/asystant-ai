import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:asystant_ai/src/mermaid/mermaid_direction.dart';
import 'package:asystant_ai/src/mermaid/network_simplex.dart';

/// A node to place, already measured.
///
/// [portSpan] is how much of the node's side facing the next or previous
/// rank can receive edges (0 for a vertex, such as a diamond's tip).
/// [nearInset] and [farInset] are how far inside its box the outline is at
/// the center of the side facing the previous and the next rank.
typedef MermaidLayoutNode = ({
  Size size,
  int? cluster,
  double portSpan,
  double nearInset,
  double farInset,
});

/// A link to route between nodes [from] and [to] (indices), spanning at
/// least [length] ranks, with the measured size of its label if any.
typedef MermaidLayoutEdge = ({int from, int to, int length, Size? label});

/// A subgraph frame: its parent's index and its measured title.
typedef MermaidLayoutCluster = ({int? parent, Size title});

/// Where a link runs, from its source to its target, in scene space.
///
/// A [loop] goes from a node back to itself and its four points are a
/// cubic Bézier; otherwise the points are joined by curves that leave and
/// enter each point along the direction of the flow.
typedef MermaidRoute = ({List<Offset> points, Rect? label, bool loop});

/// A subgraph frame and where its title goes, in scene space.
typedef MermaidFrame = ({Rect bounds, Rect title});

/// Gaps the layout keeps, in logical pixels at the diagram's text size.
@immutable
class MermaidSpacing {
  const MermaidSpacing({
    this.nodeGap = 28,
    this.edgeGap = 14,
    this.rankGap = 44,
    this.clusterPadding = 12,
    this.clusterGap = 16,
    this.titleGap = 6,
    this.margin = 12,
    this.loopSize = 16,
    this.portGap = 18,
  });

  /// Between two nodes of the same rank.
  final double nodeGap;

  /// Between an edge passing through a rank and its neighbors.
  final double edgeGap;

  /// Between two consecutive ranks of nodes.
  final double rankGap;

  /// Inside a subgraph frame, around its content.
  final double clusterPadding;

  /// Outside a subgraph frame.
  final double clusterGap;

  /// Between a frame's title and its content.
  final double titleGap;

  /// Around the whole diagram.
  final double margin;

  /// How far a self loop bulges out of its node.
  final double loopSize;

  /// Preferred distance between edges sharing a node's side.
  final double portGap;

  MermaidSpacing scaled(double factor) => MermaidSpacing(
    nodeGap: nodeGap * factor,
    edgeGap: edgeGap * factor,
    rankGap: rankGap * factor,
    clusterPadding: clusterPadding * factor,
    clusterGap: clusterGap * factor,
    titleGap: titleGap * factor,
    margin: margin * factor,
    loopSize: loopSize * factor,
    portGap: portGap * factor,
  );

  @override
  bool operator ==(Object other) =>
      other is MermaidSpacing &&
      nodeGap == other.nodeGap &&
      edgeGap == other.edgeGap &&
      rankGap == other.rankGap &&
      clusterPadding == other.clusterPadding &&
      clusterGap == other.clusterGap &&
      titleGap == other.titleGap &&
      margin == other.margin &&
      loopSize == other.loopSize &&
      portGap == other.portGap;

  @override
  int get hashCode => Object.hash(
    nodeGap,
    edgeGap,
    rankGap,
    clusterPadding,
    clusterGap,
    titleGap,
    margin,
    loopSize,
    portGap,
  );
}

/// Placed nodes, routed edges and framed subgraphs, in scene space: the
/// origin at the diagram's top left, one unit per logical pixel.
@immutable
class MermaidLayoutResult {
  const MermaidLayoutResult({
    required this.size,
    required this.nodes,
    required this.routes,
    required this.frames,
  });

  final Size size;

  /// Each node's box, in input order.
  final List<Rect> nodes;

  /// Each edge's route, in input order.
  final List<MermaidRoute> routes;

  /// Each subgraph's frame, in input order; null when it has no nodes.
  final List<MermaidFrame?> frames;
}

/// Layered (Sugiyama) layout of a flowchart, deterministic for one input.
///
/// 1. Cycles are broken by reversing the back edges a depth-first search
///    finds, in source order.
/// 2. Ranks come from network simplex. Every edge spans at least two ranks,
///    so the rank between two nodes can hold the edge's label as a node of
///    its own and labels never overlap boxes.
/// 3. Edges longer than one rank pass through one placeholder per rank.
/// 4. Barycentric sweeps order each rank, keeping every subgraph contiguous
///    and sibling subgraphs in the same order on every rank; the order with
///    the fewest crossings is kept.
/// 5. Positions along each rank come from network simplex on Graphviz's
///    auxiliary graph: straight long edges, exact gaps, and subgraph frames
///    with shared left and right sides so they are rectangles.
abstract final class MermaidLayout {
  /// Null only if the constraints turn out inconsistent, which the caller
  /// treats like source it cannot draw.
  static MermaidLayoutResult? compute({
    required MermaidDirection direction,
    required List<MermaidLayoutNode> nodes,
    required List<MermaidLayoutEdge> edges,
    List<MermaidLayoutCluster> clusters = const [],
    MermaidSpacing spacing = const MermaidSpacing(),
  }) => nodes.isEmpty
      ? null
      : _LayeredLayout(direction, nodes, edges, clusters, spacing).run();
}

class _LayeredLayout {
  _LayeredLayout(
    this.direction,
    this.nodes,
    this.edges,
    this.clusters,
    this.spacing,
  );

  final MermaidDirection direction;

  final List<MermaidLayoutNode> nodes;

  final List<MermaidLayoutEdge> edges;

  final List<MermaidLayoutCluster> clusters;

  final MermaidSpacing spacing;

  /// Ordering sweeps; the best of them is kept.
  static const int _sweeps = 8;

  // Per item: the real nodes first, then one placeholder per rank crossed.
  final List<int> _rank = [];

  final List<int?> _cluster = [];

  /// Extent along the rank (across the flow).
  final List<double> _breadth = [];

  /// Extent along the flow.
  final List<double> _depth = [];

  final List<bool> _real = [];

  /// The edge a placeholder belongs to; null for real nodes.
  final List<int?> _itemEdge = [];

  final List<List<int>> _predecessors = [];

  final List<List<int>> _successors = [];

  /// Room a node's self loops take beside it, along the rank.
  late final List<double> _loopRoom = List.filled(nodes.length, 0);

  late final List<bool> _reversed = List.filled(edges.length, false);

  /// Items each edge passes through, from the lower rank; null for loops.
  late final List<List<int>?> _chains = List.filled(edges.length, null);

  late final List<int?> _labelItem = List.filled(edges.length, null);

  late final List<int?> _clusterMin = List.filled(clusters.length, null);

  late final List<int?> _clusterMax = List.filled(clusters.length, null);

  /// Each rank, left to right: items (≥ 0) and frame sides (< 0, see
  /// [_leftSide] and [_rightSide]).
  List<List<int>> _layers = [];

  final List<int> _position = [];

  bool get _vertical => direction.isVertical;

  int get _itemCount => _rank.length;

  static int _leftSide(int cluster) => -(2 * cluster + 1);

  static int _rightSide(int cluster) => -(2 * cluster + 2);

  MermaidLayoutResult? run() {
    _addRealItems();
    _breakCycles();
    if (!_assignRanks()) {
      return null;
    }
    _buildChains();
    _measureClusters();
    _order();
    final across = _placeAcross();
    if (across == null) {
      return null;
    }
    return _assemble(across);
  }

  void _addRealItems() {
    for (final node in nodes) {
      _addItem(rank: 0, cluster: node.cluster, size: node.size);
    }
  }

  int _addItem({
    required int rank,
    required int? cluster,
    required Size size,
    int? edge,
  }) {
    _rank.add(rank);
    _cluster.add(cluster);
    _breadth.add(_vertical ? size.width : size.height);
    _depth.add(_vertical ? size.height : size.width);
    _real.add(edge == null);
    _itemEdge.add(edge);
    _predecessors.add([]);
    _successors.add([]);
    return _rank.length - 1;
  }

  bool _isLoop(int edge) => edges[edge].from == edges[edge].to;

  /// Depth-first from each node in source order; an edge back into the
  /// active path closes a cycle and is laid out reversed.
  void _breakCycles() {
    final outgoing = List.generate(nodes.length, (_) => <int>[]);
    for (var edge = 0; edge < edges.length; edge++) {
      if (!_isLoop(edge)) {
        outgoing[edges[edge].from].add(edge);
      }
    }
    final state = List.filled(nodes.length, 0);
    final next = List.filled(nodes.length, 0);
    for (var start = 0; start < nodes.length; start++) {
      if (state[start] != 0) {
        continue;
      }
      state[start] = 1;
      final stack = [start];
      while (stack.isNotEmpty) {
        final node = stack.last;
        if (next[node] == outgoing[node].length) {
          state[node] = 2;
          stack.removeLast();
          continue;
        }
        final edge = outgoing[node][next[node]++];
        final target = edges[edge].to;
        if (state[target] == 1) {
          _reversed[edge] = true;
        } else if (state[target] == 0) {
          state[target] = 1;
          stack.add(target);
        }
      }
    }
  }

  (int, int) _layoutEnds(int edge) => _reversed[edge]
      ? (edges[edge].to, edges[edge].from)
      : (edges[edge].from, edges[edge].to);

  bool _assignRanks() {
    final ranks = NetworkSimplex.solve(nodes.length, [
      for (var edge = 0; edge < edges.length; edge++)
        if (!_isLoop(edge))
          (
            from: _layoutEnds(edge).$1,
            to: _layoutEnds(edge).$2,
            minLength: 2 * math.max(1, edges[edge].length),
            weight: 1,
          ),
    ]);
    if (ranks == null) {
      return false;
    }
    _rank.setAll(0, ranks);
    return true;
  }

  int? _parentOf(int cluster) => clusters[cluster].parent;

  /// Whether [cluster] is [ancestor] or inside it.
  bool _within(int? cluster, int ancestor) {
    for (var current = cluster; current != null; current = _parentOf(current)) {
      if (current == ancestor) {
        return true;
      }
    }
    return false;
  }

  /// The innermost subgraph containing both, or null.
  int? _commonCluster(int? a, int? b) {
    for (var current = a; current != null; current = _parentOf(current)) {
      if (_within(b, current)) {
        return current;
      }
    }
    return null;
  }

  void _buildChains() {
    for (var edge = 0; edge < edges.length; edge++) {
      if (_isLoop(edge)) {
        final node = edges[edge].from;
        final label = edges[edge].label;
        _loopRoom[node] +=
            spacing.loopSize * 1.4 +
            (label == null
                ? 0
                : (_vertical ? label.width : label.height) + spacing.edgeGap);
        continue;
      }
      final (upper, lower) = _layoutEnds(edge);
      final cluster = _commonCluster(_cluster[upper], _cluster[lower]);
      final label = edges[edge].label;
      final labelRank = (_rank[upper] + _rank[lower]) ~/ 2;
      final chain = [upper];
      for (var rank = _rank[upper] + 1; rank < _rank[lower]; rank++) {
        final isLabel = label != null && rank == labelRank;
        final item = _addItem(
          rank: rank,
          cluster: cluster,
          size: isLabel ? label : Size.zero,
          edge: edge,
        );
        if (isLabel) {
          _labelItem[edge] = item;
        }
        chain.add(item);
      }
      chain.add(lower);
      for (var index = 1; index < chain.length; index++) {
        _successors[chain[index - 1]].add(chain[index]);
        _predecessors[chain[index]].add(chain[index - 1]);
      }
      _chains[edge] = chain;
    }
  }

  void _measureClusters() {
    for (var item = 0; item < _itemCount; item++) {
      for (var c = _cluster[item]; c != null; c = _parentOf(c)) {
        final rank = _rank[item];
        _clusterMin[c] = math.min(_clusterMin[c] ?? rank, rank);
        _clusterMax[c] = math.max(_clusterMax[c] ?? rank, rank);
      }
    }
  }

  bool _spans(int cluster, int rank) =>
      (_clusterMin[cluster] ?? rank + 1) <= rank &&
      rank <= (_clusterMax[cluster] ?? -1);

  int get _rankCount => _rank.reduce(math.max) + 1;

  // ---------------------------------------------------------------------
  // Ordering.

  /// Orders the ranks twice — once following edges in source order, once
  /// sending the chains of reversed (back) edges first so they run along
  /// the outside — and keeps the result with fewer crossings.
  void _order() {
    _position
      ..clear()
      ..addAll(List.filled(_itemCount, 0));
    final (forward, forwardCrossings) = _orderFrom(backEdgesFirst: false);
    if (forwardCrossings == 0 || !_reversed.contains(true)) {
      _layers = forward;
    } else {
      final (outside, outsideCrossings) = _orderFrom(backEdgesFirst: true);
      _layers = outsideCrossings < forwardCrossings ? outside : forward;
    }
    _refreshPositions();
  }

  (List<List<int>>, int) _orderFrom({required bool backEdgesFirst}) {
    // Initial order: depth first along the flow, in source order.
    final initial = List.generate(_rankCount, (_) => <int>[]);
    final visited = List.filled(_itemCount, false);
    final roots = List.generate(nodes.length, (index) => index)
      ..sort((a, b) => _rank[a] == _rank[b] ? a - b : _rank[a] - _rank[b]);
    for (final root in roots) {
      final stack = [root];
      while (stack.isNotEmpty) {
        final item = stack.removeLast();
        if (visited[item]) {
          continue;
        }
        visited[item] = true;
        initial[_rank[item]].add(item);
        final successors = backEdgesFirst
            ? [
                ..._successors[item].where(_onBackEdge),
                ..._successors[item].where((next) => !_onBackEdge(next)),
              ]
            : _successors[item];
        stack.addAll(successors.reversed);
      }
    }
    _layers = initial;
    _refreshPositions();
    final keys = _clusterKeys();
    _layers = [
      for (var rank = 0; rank < _rankCount; rank++)
        _arrange(rank, (item) => _position[item].toDouble(), keys),
    ];
    _refreshPositions();

    var best = [
      for (final layer in _layers) [...layer],
    ];
    var bestCrossings = _crossings();
    for (var sweep = 0; sweep < _sweeps && bestCrossings > 0; sweep++) {
      final down = sweep.isEven;
      final sweepKeys = _clusterKeys();
      final ranks = down
          ? List.generate(_rankCount, (rank) => rank)
          : List.generate(_rankCount, (rank) => _rankCount - 1 - rank);
      for (final rank in ranks) {
        _layers[rank] = _arrange(
          rank,
          (item) => _barycenter(item, down),
          sweepKeys,
        );
        _refreshLayer(rank);
      }
      final crossings = _crossings();
      if (crossings < bestCrossings) {
        bestCrossings = crossings;
        best = [
          for (final layer in _layers) [...layer],
        ];
      }
    }
    return (best, bestCrossings);
  }

  /// A placeholder on a reversed edge's chain.
  bool _onBackEdge(int item) => switch (_itemEdge[item]) {
    final edge? => _reversed[edge],
    null => false,
  };

  void _refreshPositions() {
    for (var rank = 0; rank < _layers.length; rank++) {
      _refreshLayer(rank);
    }
  }

  void _refreshLayer(int rank) {
    var index = 0;
    for (final entry in _layers[rank]) {
      if (entry >= 0) {
        _position[entry] = index++;
      }
    }
  }

  double _barycenter(int item, bool down) {
    final neighbors = down ? _predecessors[item] : _successors[item];
    if (neighbors.isEmpty) {
      return _position[item].toDouble();
    }
    var sum = 0.0;
    for (final neighbor in neighbors) {
      sum += _position[neighbor];
    }
    return sum / neighbors.length;
  }

  /// One key per subgraph for a whole sweep, so sibling subgraphs keep the
  /// same order on every rank (otherwise their frames could not be
  /// rectangles): the mean position of everything inside.
  List<double> _clusterKeys() {
    final sums = List.filled(clusters.length, 0.0);
    final counts = List.filled(clusters.length, 0);
    for (var item = 0; item < _itemCount; item++) {
      for (var c = _cluster[item]; c != null; c = _parentOf(c)) {
        sums[c] += _position[item];
        counts[c]++;
      }
    }
    return [
      for (var c = 0; c < clusters.length; c++)
        counts[c] == 0 ? c.toDouble() : sums[c] / counts[c],
    ];
  }

  List<int> _arrange(
    int rank,
    double Function(int item) keyOf,
    List<double> clusterKeys,
  ) => _arrangeWithin(
    null,
    rank,
    [
      for (final entry in _layers[rank])
        if (entry >= 0) entry,
    ],
    keyOf,
    clusterKeys,
  );

  /// The child of [parent] on the way to [cluster], or null when the item
  /// sits directly in [parent].
  int? _childOnPath(int? cluster, int? parent) {
    int? child;
    for (
      var current = cluster;
      current != parent;
      current = _parentOf(current!)
    ) {
      child = current;
    }
    return child;
  }

  List<int> _arrangeWithin(
    int? parent,
    int rank,
    List<int> items,
    double Function(int item) keyOf,
    List<double> clusterKeys,
  ) {
    final groups = <int, List<int>>{};
    final units = <(double, double, int)>[];
    for (final item in items) {
      final child = _childOnPath(_cluster[item], parent);
      if (child == null) {
        units.add((keyOf(item), _position[item].toDouble(), item));
      } else {
        groups.putIfAbsent(child, () => []).add(item);
      }
    }
    for (var c = 0; c < clusters.length; c++) {
      if (_parentOf(c) == parent && _spans(c, rank)) {
        groups.putIfAbsent(c, () => []);
      }
    }
    for (final c in groups.keys) {
      units.add((clusterKeys[c], c.toDouble(), _leftSide(c)));
    }
    units.sort((a, b) {
      final byKey = a.$1.compareTo(b.$1);
      return byKey != 0 ? byKey : a.$2.compareTo(b.$2);
    });
    return [
      for (final (_, _, unit) in units)
        if (unit >= 0)
          unit
        else ...[
          unit,
          ..._arrangeWithin(
            (-unit - 1) ~/ 2,
            rank,
            groups[(-unit - 1) ~/ 2]!,
            keyOf,
            clusterKeys,
          ),
          _rightSide((-unit - 1) ~/ 2),
        ],
    ];
  }

  int _crossings() {
    var total = 0;
    for (var rank = 0; rank + 1 < _layers.length; rank++) {
      final segments = <(int, int)>[
        for (final item in _layers[rank])
          if (item >= 0)
            for (final next in _successors[item])
              (_position[item], _position[next]),
      ];
      for (var i = 0; i < segments.length; i++) {
        for (var j = i + 1; j < segments.length; j++) {
          final (a1, b1) = segments[i];
          final (a2, b2) = segments[j];
          if ((a1 - a2) * (b1 - b2) < 0) {
            total++;
          }
        }
      }
    }
    return total;
  }

  // ---------------------------------------------------------------------
  // Positions along each rank.

  int _variable(int entry) => entry >= 0 ? entry : _itemCount + (-entry - 1);

  double _titleBand(int cluster) =>
      clusters[cluster].title.height + spacing.titleGap;

  /// Centers of items and frame sides along the ranks, or null.
  List<double>? _placeAcross() {
    final constraints = <SimplexEdge>[];
    for (final layer in _layers) {
      for (var index = 0; index + 1 < layer.length; index++) {
        final left = layer[index];
        final right = layer[index + 1];
        constraints.add((
          from: _variable(left),
          to: _variable(right),
          minLength: _separation(left, right).ceil(),
          weight: 0,
        ));
      }
    }
    for (var c = 0; c < clusters.length; c++) {
      if (_clusterMin[c] == null) {
        continue;
      }
      // Wide enough for the title above the content; as narrow as allowed.
      constraints.add((
        from: _variable(_leftSide(c)),
        to: _variable(_rightSide(c)),
        minLength: _vertical
            ? (clusters[c].title.width + 2 * spacing.clusterPadding).ceil()
            : 0,
        weight: 1,
      ));
    }
    var helper = _itemCount + 2 * clusters.length;
    for (var item = 0; item < _itemCount; item++) {
      for (final next in _successors[item]) {
        // Graphviz's weights, so long edges stay straight; doubled for
        // forward edges, so a back edge bends before the flow does.
        final base = switch ((_real[item], _real[next])) {
          (true, true) => 1,
          (false, false) => 8,
          _ => 2,
        };
        final weight = _onBackEdge(item) || _onBackEdge(next) ? base : 2 * base;
        constraints
          ..add((from: helper, to: item, minLength: 0, weight: weight))
          ..add((from: helper, to: next, minLength: 0, weight: weight));
        helper++;
      }
    }
    final placed = NetworkSimplex.solve(helper, constraints, balance: true);
    return placed?.map((value) => value.toDouble()).toList();
  }

  double _separation(int left, int right) {
    final leftHalf = left >= 0 ? _breadth[left] / 2 + _loopAt(left) : 0.0;
    final rightHalf = right >= 0 ? _breadth[right] / 2 : 0.0;
    final leftCluster = left < 0 ? (-left - 1) ~/ 2 : null;
    final rightCluster = right < 0 ? (-right - 1) ~/ 2 : null;
    final leftIsOpening = left < 0 && (-left - 1).isEven;
    final rightIsClosing = right < 0 && (-right - 1).isOdd;
    final gap = switch (()) {
      _ when leftIsOpening && rightIsClosing && leftCluster == rightCluster =>
        0.0,
      _ when leftIsOpening =>
        spacing.clusterPadding + (_vertical ? 0 : _titleBand(leftCluster!)),
      _ when rightIsClosing => spacing.clusterPadding,
      _ when left < 0 || right < 0 =>
        (left >= 0 && !_real[left]) || (right >= 0 && !_real[right])
            ? spacing.edgeGap
            : spacing.clusterGap,
      _ when _real[left] && _real[right] => spacing.nodeGap,
      _ => spacing.edgeGap,
    };
    return leftHalf + gap + rightHalf;
  }

  double _loopAt(int item) => item < nodes.length ? _loopRoom[item] : 0;

  // ---------------------------------------------------------------------
  // Positions along the flow, ports and the final geometry.

  /// Room a frame needs before ([before]) or after its first or last rank,
  /// including frames nested in it that start or end on the same rank.
  double _frameRoom(int cluster, {required bool before}) {
    final titled = _vertical && (before != direction.isReversed);
    var nested = 0.0;
    for (var c = 0; c < clusters.length; c++) {
      if (_parentOf(c) == cluster &&
          _clusterMin[c] != null &&
          (before
              ? _clusterMin[c] == _clusterMin[cluster]
              : _clusterMax[c] == _clusterMax[cluster])) {
        nested = math.max(nested, _frameRoom(c, before: before));
      }
    }
    return spacing.clusterPadding + (titled ? _titleBand(cluster) : 0) + nested;
  }

  MermaidLayoutResult _assemble(List<double> across) {
    final rankCount = _rankCount;
    final depth = List.filled(rankCount, 0.0);
    for (var item = 0; item < _itemCount; item++) {
      depth[_rank[item]] = math.max(depth[_rank[item]], _depth[item]);
    }
    final roomBefore = List.filled(rankCount, 0.0);
    final roomAfter = List.filled(rankCount, 0.0);
    for (var c = 0; c < clusters.length; c++) {
      final (first, last) = (_clusterMin[c], _clusterMax[c]);
      if (first == null || last == null) {
        continue;
      }
      roomBefore[first] = math.max(
        roomBefore[first],
        _frameRoom(c, before: true),
      );
      roomAfter[last] = math.max(roomAfter[last], _frameRoom(c, before: false));
    }
    // Along the flow: each rank's center.
    final along = List.filled(rankCount, 0.0);
    var cursor = spacing.margin + roomBefore[0];
    for (var rank = 0; rank < rankCount; rank++) {
      if (rank > 0) {
        final frames = roomAfter[rank - 1] + roomBefore[rank];
        cursor += math.max(
          spacing.rankGap / 2,
          frames + (frames > 0 ? spacing.edgeGap : 0),
        );
      }
      along[rank] = cursor + depth[rank] / 2;
      cursor += depth[rank];
    }
    final alongExtent = cursor + roomAfter[rankCount - 1] + spacing.margin;

    // Across the flow: shift so the leftmost edge sits at the margin.
    var low = double.infinity;
    var high = double.negativeInfinity;
    for (var item = 0; item < _itemCount; item++) {
      low = math.min(low, across[item] - _breadth[item] / 2);
      high = math.max(high, across[item] + _breadth[item] / 2 + _loopAt(item));
    }
    for (var c = 0; c < clusters.length; c++) {
      if (_clusterMin[c] != null) {
        low = math.min(low, across[_variable(_leftSide(c))]);
        high = math.max(high, across[_variable(_rightSide(c))]);
      }
    }
    final shift = spacing.margin - low;
    final acrossExtent = high - low + 2 * spacing.margin;
    final size = _vertical
        ? Size(acrossExtent, alongExtent)
        : Size(alongExtent, acrossExtent);

    Offset toScene(double acrossValue, double alongValue) {
      final flow = direction.isReversed ? alongExtent - alongValue : alongValue;
      final side = acrossValue + shift;
      return _vertical ? Offset(side, flow) : Offset(flow, side);
    }

    Offset center(int item) => toScene(across[item], along[_rank[item]]);

    final boxes = [
      for (var node = 0; node < nodes.length; node++)
        Rect.fromCenter(
          center: center(node),
          width: nodes[node].size.width,
          height: nodes[node].size.height,
        ),
    ];

    final ports = _ports(across);
    final routes = <MermaidRoute>[];
    final loopCount = List.filled(nodes.length, 0);
    for (var edge = 0; edge < edges.length; edge++) {
      final chain = _chains[edge];
      if (chain == null) {
        final node = edges[edge].from;
        routes.add(
          _loopRoute(edge, node, across, along, loopCount[node]++, toScene),
        );
        continue;
      }
      final points = <Offset>[
        toScene(
          ports[(edge, true)]!,
          along[_rank[chain.first]] + _portDepth(chain.first, far: true),
        ),
        // Odd ranks never hold nodes: a plain placeholder there adds a bend
        // and avoids nothing, so the curve skips it.
        for (final item in chain.sublist(1, chain.length - 1))
          if (_rank[item].isEven || item == _labelItem[edge]) center(item),
        toScene(
          ports[(edge, false)]!,
          along[_rank[chain.last]] - _portDepth(chain.last, far: false),
        ),
      ];
      final labelItem = _labelItem[edge];
      routes.add((
        points: _reversed[edge] ? points.reversed.toList() : points,
        label: labelItem == null
            ? null
            : Rect.fromCenter(
                center: center(labelItem),
                width: edges[edge].label!.width,
                height: edges[edge].label!.height,
              ),
        loop: false,
      ));
    }

    final frames = <MermaidFrame?>[
      for (var c = 0; c < clusters.length; c++)
        if (_clusterMin[c] case final first?)
          _frame(
            c,
            Rect.fromPoints(
              toScene(
                across[_variable(_leftSide(c))],
                along[first] - depth[first] / 2 - _frameRoom(c, before: true),
              ),
              toScene(
                across[_variable(_rightSide(c))],
                along[_clusterMax[c]!] +
                    depth[_clusterMax[c]!] / 2 +
                    _frameRoom(c, before: false),
              ),
            ),
          )
        else
          null,
    ];
    return MermaidLayoutResult(
      size: size,
      nodes: boxes,
      routes: routes,
      frames: frames,
    );
  }

  /// Distance from a node's center to where its edges attach along the
  /// flow: half its depth, less the outline's inset on that side.
  double _portDepth(int item, {required bool far}) {
    if (item >= nodes.length) {
      return 0;
    }
    final inset = far ? nodes[item].farInset : nodes[item].nearInset;
    return _depth[item] / 2 - inset;
  }

  /// Where each edge end attaches across the flow: edges sharing a side are
  /// spread over its usable span, in the order of where they come from, so
  /// they do not cross at the node. Keyed by (edge, isStart).
  Map<(int, bool), double> _ports(List<double> across) {
    final sides = <(int, bool), List<(double, int, bool)>>{};
    for (var edge = 0; edge < edges.length; edge++) {
      final chain = _chains[edge];
      if (chain == null) {
        continue;
      }
      sides.putIfAbsent((chain.first, true), () => []).add((
        across[chain[1]],
        edge,
        true,
      ));
      sides.putIfAbsent((chain.last, false), () => []).add((
        across[chain[chain.length - 2]],
        edge,
        false,
      ));
    }
    final ports = <(int, bool), double>{};
    for (final MapEntry(key: (node, _), value: ends) in sides.entries) {
      ends.sort((a, b) {
        final byPosition = a.$1.compareTo(b.$1);
        return byPosition != 0 ? byPosition : a.$2 - b.$2;
      });
      final span = math.min(
        nodes[node].portSpan,
        spacing.portGap * (ends.length - 1),
      );
      for (var index = 0; index < ends.length; index++) {
        final (_, edge, isStart) = ends[index];
        final offset = ends.length == 1
            ? 0.0
            : -span / 2 + span * index / (ends.length - 1);
        ports[(edge, isStart)] = across[node] + offset;
      }
    }
    return ports;
  }

  MermaidRoute _loopRoute(
    int edge,
    int node,
    List<double> across,
    List<double> along,
    int nth,
    Offset Function(double across, double along) toScene,
  ) {
    final side = across[node] + _breadth[node] / 2;
    final center = along[_rank[node]];
    final reach = spacing.loopSize * (1.4 + .5 * nth);
    final spread = _depth[node] / 4;
    final label = edges[edge].label;
    return (
      points: [
        toScene(side, center - spread),
        toScene(side + reach * 1.3, center - spread - reach * .4),
        toScene(side + reach * 1.3, center + spread + reach * .4),
        toScene(side, center + spread),
      ],
      label: label == null
          ? null
          : Rect.fromCenter(
              center: toScene(
                side +
                    reach +
                    spacing.edgeGap / 2 +
                    (_vertical ? label.width : label.height) / 2,
                center,
              ),
              width: label.width,
              height: label.height,
            ),
      loop: true,
    );
  }

  MermaidFrame _frame(int cluster, Rect bounds) {
    final title = clusters[cluster].title;
    final width = math.min(
      title.width,
      math.max(0.0, bounds.width - 2 * spacing.clusterPadding),
    );
    return (
      bounds: bounds,
      title: Rect.fromLTWH(
        bounds.left + spacing.clusterPadding,
        bounds.top + spacing.clusterPadding * .75,
        width,
        title.height,
      ),
    );
  }
}
