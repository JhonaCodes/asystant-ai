/// One constraint of a [NetworkSimplex] problem: `rank[to] − rank[from]`
/// must be at least [minLength], and costs [weight] per unit of length.
typedef SimplexEdge = ({int from, int to, int minLength, int weight});

/// Integer network simplex (Gansner et al., "A technique for drawing
/// directed graphs", 1993): assigns each node an integer rank that satisfies
/// every [SimplexEdge] and minimizes `Σ weight × (rank[to] − rank[from])`.
///
/// The layout uses it twice: to put nodes into ranks, and to place them
/// along each rank with Graphviz's auxiliary-graph construction.
abstract final class NetworkSimplex {
  /// Ranks for nodes `0 … nodeCount − 1`, the smallest of each connected
  /// component at 0; null when the constraints contain a cycle.
  ///
  /// [balance] centers subtrees whose position does not change the cost,
  /// so a node with two children sits between them instead of over one.
  /// After [maxPivots] exchanges the current, feasible ranks are returned.
  static List<int>? solve(
    int nodeCount,
    Iterable<SimplexEdge> edges, {
    bool balance = false,
    int maxPivots = 4000,
  }) {
    // Parallel edges become one: the longest minimum, the summed weight.
    final merged = <int, SimplexEdge>{};
    for (final edge in edges) {
      if (edge.from == edge.to) {
        if (edge.minLength > 0) {
          return null;
        }
        continue;
      }
      final key = edge.from * nodeCount + edge.to;
      final known = merged[key];
      merged[key] = known == null
          ? edge
          : (
              from: edge.from,
              to: edge.to,
              minLength: known.minLength > edge.minLength
                  ? known.minLength
                  : edge.minLength,
              weight: known.weight + edge.weight,
            );
    }
    final components = _components(nodeCount, merged.values);
    final ranks = List.filled(nodeCount, 0);
    for (final (nodes, componentEdges) in components) {
      final solved = _Component(
        nodes.length,
        componentEdges,
      ).solve(balance: balance, maxPivots: maxPivots);
      if (solved == null) {
        return null;
      }
      for (var local = 0; local < nodes.length; local++) {
        ranks[nodes[local]] = solved[local];
      }
    }
    return ranks;
  }

  /// Weakly connected components, with edges renumbered to local indices.
  static List<(List<int>, List<SimplexEdge>)> _components(
    int nodeCount,
    Iterable<SimplexEdge> edges,
  ) {
    final root = List.generate(nodeCount, (index) => index);
    int find(int node) {
      var current = node;
      while (root[current] != current) {
        root[current] = root[root[current]];
        current = root[current];
      }
      return current;
    }

    for (final edge in edges) {
      final a = find(edge.from);
      final b = find(edge.to);
      if (a != b) {
        root[a > b ? a : b] = a > b ? b : a;
      }
    }
    final groups = <int, List<int>>{};
    final local = List.filled(nodeCount, 0);
    for (var node = 0; node < nodeCount; node++) {
      final group = groups.putIfAbsent(find(node), () => []);
      local[node] = group.length;
      group.add(node);
    }
    final groupEdges = <int, List<SimplexEdge>>{};
    for (final edge in edges) {
      groupEdges.putIfAbsent(find(edge.from), () => []).add((
        from: local[edge.from],
        to: local[edge.to],
        minLength: edge.minLength,
        weight: edge.weight,
      ));
    }
    return [
      for (final MapEntry(key: id, value: nodes) in groups.entries)
        (nodes, groupEdges[id] ?? const []),
    ];
  }
}

/// The simplex over one connected component, in local node indices.
class _Component {
  _Component(this.nodeCount, List<SimplexEdge> edges)
    : _from = [for (final edge in edges) edge.from],
      _to = [for (final edge in edges) edge.to],
      _minLength = [for (final edge in edges) edge.minLength],
      _weight = [for (final edge in edges) edge.weight],
      _incident = List.generate(nodeCount, (_) => <int>[]),
      _treeIncident = List.generate(nodeCount, (_) => <int>[]),
      _inTree = List.filled(edges.length, false),
      _cut = List.filled(edges.length, 0),
      _rank = List.filled(nodeCount, 0),
      _parentEdge = List.filled(nodeCount, -1),
      _low = List.filled(nodeCount, 0),
      _lim = List.filled(nodeCount, 0) {
    for (var edge = 0; edge < edges.length; edge++) {
      _incident[_from[edge]].add(edge);
      _incident[_to[edge]].add(edge);
    }
  }

  final int nodeCount;

  final List<int> _from;

  final List<int> _to;

  final List<int> _minLength;

  final List<int> _weight;

  final List<List<int>> _incident;

  final List<List<int>> _treeIncident;

  final List<bool> _inTree;

  final List<int> _cut;

  final List<int> _rank;

  final List<int> _parentEdge;

  final List<int> _low;

  final List<int> _lim;

  /// Tree nodes from the root, parents before children.
  final List<int> _preorder = [];

  int get _edgeCount => _from.length;

  int _slack(int edge) =>
      _rank[_to[edge]] - _rank[_from[edge]] - _minLength[edge];

  int _other(int edge, int node) =>
      _from[edge] == node ? _to[edge] : _from[edge];

  List<int>? solve({required bool balance, required int maxPivots}) {
    if (nodeCount == 1) {
      return [0];
    }
    if (!_longestPath() || !_feasibleTree()) {
      return null;
    }
    _initTree();
    for (var pivot = 0; pivot < maxPivots; pivot++) {
      final leaving = _leavingEdge();
      if (leaving < 0) {
        break;
      }
      final entering = _enteringEdge(leaving);
      if (entering < 0) {
        break;
      }
      _inTree[leaving] = false;
      _treeIncident[_from[leaving]].remove(leaving);
      _treeIncident[_to[leaving]].remove(leaving);
      _addTreeEdge(entering);
      _initTree();
      _updateRanks();
    }
    if (balance) {
      _balance();
    }
    final lowest = _rank.reduce((a, b) => a < b ? a : b);
    return [for (final rank in _rank) rank - lowest];
  }

  /// Initial feasible ranks: each node as low as its successors allow.
  /// False when the edges contain a cycle.
  bool _longestPath() {
    final state = List.filled(nodeCount, 0);
    final next = List.filled(nodeCount, 0);
    for (var start = 0; start < nodeCount; start++) {
      if (state[start] != 0) {
        continue;
      }
      final stack = [start];
      state[start] = 1;
      while (stack.isNotEmpty) {
        final node = stack.last;
        final incident = _incident[node];
        if (next[node] < incident.length) {
          final edge = incident[next[node]++];
          if (_from[edge] != node) {
            continue;
          }
          final successor = _to[edge];
          if (state[successor] == 1) {
            return false;
          }
          if (state[successor] == 0) {
            state[successor] = 1;
            stack.add(successor);
          }
          continue;
        }
        var rank = 0;
        var first = true;
        for (final edge in incident) {
          if (_from[edge] == node) {
            final candidate = _rank[_to[edge]] - _minLength[edge];
            rank = first || candidate < rank ? candidate : rank;
            first = false;
          }
        }
        _rank[node] = rank;
        state[node] = 2;
        stack.removeLast();
      }
    }
    return true;
  }

  /// Grows a spanning tree of tight edges, shifting the tree's ranks to
  /// tighten the cheapest edge leaving it whenever it gets stuck.
  bool _feasibleTree() {
    final inTreeNode = List.filled(nodeCount, false);
    final treeNodes = [0];
    inTreeNode[0] = true;
    while (true) {
      final stack = [...treeNodes];
      while (stack.isNotEmpty) {
        final node = stack.removeLast();
        for (final edge in _incident[node]) {
          final other = _other(edge, node);
          if (!inTreeNode[other] && _slack(edge) == 0) {
            inTreeNode[other] = true;
            treeNodes.add(other);
            stack.add(other);
            _addTreeEdge(edge);
          }
        }
      }
      if (treeNodes.length == nodeCount) {
        return true;
      }
      var best = -1;
      for (var edge = 0; edge < _edgeCount; edge++) {
        if (inTreeNode[_from[edge]] != inTreeNode[_to[edge]] &&
            (best < 0 || _slack(edge) < _slack(best))) {
          best = edge;
        }
      }
      if (best < 0) {
        return false;
      }
      final delta = inTreeNode[_from[best]] ? _slack(best) : -_slack(best);
      for (final node in treeNodes) {
        _rank[node] += delta;
      }
    }
  }

  void _addTreeEdge(int edge) {
    _inTree[edge] = true;
    _treeIncident[_from[edge]].add(edge);
    _treeIncident[_to[edge]].add(edge);
  }

  /// Postorder limits, parents and cut values for the current tree.
  void _initTree() {
    _preorder.clear();
    final postorder = <int>[];
    final next = List.filled(nodeCount, 0);
    var nextLim = 1;
    _parentEdge[0] = -1;
    _low[0] = nextLim;
    _preorder.add(0);
    final stack = [0];
    while (stack.isNotEmpty) {
      final node = stack.last;
      final tree = _treeIncident[node];
      if (next[node] < tree.length) {
        final edge = tree[next[node]++];
        if (edge == _parentEdge[node]) {
          continue;
        }
        final child = _other(edge, node);
        _parentEdge[child] = edge;
        _low[child] = nextLim;
        _preorder.add(child);
        stack.add(child);
        continue;
      }
      _lim[node] = nextLim++;
      postorder.add(node);
      stack.removeLast();
    }
    for (final node in postorder) {
      if (_parentEdge[node] >= 0) {
        _cut[_parentEdge[node]] = _cutValue(node);
      }
    }
  }

  /// Cut value of the tree edge between [child] and its parent: the weight
  /// of edges from its tail side to its head side minus the reverse.
  int _cutValue(int child) {
    final parentEdge = _parentEdge[child];
    final childIsTail = _from[parentEdge] == child;
    var value = _weight[parentEdge];
    for (final edge in _incident[child]) {
      if (edge == parentEdge) {
        continue;
      }
      final isOut = _from[edge] == child;
      final pointsToHead = isOut == childIsTail;
      value += pointsToHead ? _weight[edge] : -_weight[edge];
      if (_inTree[edge]) {
        value += pointsToHead ? -_cut[edge] : _cut[edge];
      }
    }
    return value;
  }

  int _leavingEdge() {
    for (var edge = 0; edge < _edgeCount; edge++) {
      if (_inTree[edge] && _cut[edge] < 0) {
        return edge;
      }
    }
    return -1;
  }

  bool _isDescendant(int node, int root) =>
      _low[root] <= _lim[node] && _lim[node] <= _lim[root];

  /// The non-tree edge with the least slack that reconnects the two sides
  /// of [leaving] in the direction that keeps the ranks feasible.
  int _enteringEdge(int leaving) {
    var subtree = _from[leaving];
    var flip = false;
    if (_lim[_from[leaving]] > _lim[_to[leaving]]) {
      subtree = _to[leaving];
      flip = true;
    }
    var best = -1;
    for (var edge = 0; edge < _edgeCount; edge++) {
      if (flip == _isDescendant(_from[edge], subtree) &&
          flip != _isDescendant(_to[edge], subtree) &&
          (best < 0 || _slack(edge) < _slack(best))) {
        best = edge;
      }
    }
    return best;
  }

  void _updateRanks() {
    for (final node in _preorder.skip(1)) {
      final edge = _parentEdge[node];
      final parent = _other(edge, node);
      _rank[node] = _from[edge] == node
          ? _rank[parent] - _minLength[edge]
          : _rank[parent] + _minLength[edge];
    }
  }

  /// Moves each subtree hanging from a zero-cut tree edge halfway through
  /// the room it has: the cost does not change, the drawing is centered.
  void _balance() {
    for (var edge = 0; edge < _edgeCount; edge++) {
      if (!_inTree[edge] || _cut[edge] != 0) {
        continue;
      }
      final entering = _enteringEdge(edge);
      if (entering < 0) {
        continue;
      }
      final room = _slack(entering);
      if (room <= 1) {
        continue;
      }
      final tailBelow = _lim[_from[edge]] < _lim[_to[edge]];
      final root = tailBelow ? _from[edge] : _to[edge];
      final shift = tailBelow ? -(room ~/ 2) : room ~/ 2;
      for (var node = 0; node < nodeCount; node++) {
        if (_isDescendant(node, root)) {
          _rank[node] += shift;
        }
      }
    }
  }
}
