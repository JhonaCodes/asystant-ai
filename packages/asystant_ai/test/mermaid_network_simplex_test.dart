import 'dart:math';

import 'package:asystant_ai/src/mermaid/network_simplex.dart';
import 'package:flutter_test/flutter_test.dart';

int cost(List<int> ranks, List<SimplexEdge> edges) => edges.fold(
  0,
  (sum, edge) => sum + edge.weight * (ranks[edge.to] - ranks[edge.from]),
);

bool feasible(List<int> ranks, List<SimplexEdge> edges) =>
    edges.every((edge) => ranks[edge.to] - ranks[edge.from] >= edge.minLength);

/// The cheapest feasible ranks in 0..limit, by trying them all.
int bruteForce(int nodes, List<SimplexEdge> edges, int limit) {
  var best = 1 << 30;
  final ranks = List.filled(nodes, 0);
  void assign(int node) {
    if (node == nodes) {
      if (feasible(ranks, edges)) {
        best = min(best, cost(ranks, edges));
      }
      return;
    }
    for (var rank = 0; rank <= limit; rank++) {
      ranks[node] = rank;
      assign(node + 1);
    }
  }

  assign(0);
  return best;
}

void main() {
  test('finds the optimum of small random acyclic problems', () {
    final random = Random(3);
    for (var round = 0; round < 60; round++) {
      final nodes = 3 + random.nextInt(3);
      final edges = <SimplexEdge>[
        for (var from = 0; from < nodes; from++)
          for (var to = from + 1; to < nodes; to++)
            if (random.nextDouble() < .55)
              (
                from: from,
                to: to,
                minLength: 1 + random.nextInt(2),
                weight: 1 + random.nextInt(3),
              ),
      ];
      final ranks = NetworkSimplex.solve(nodes, edges)!;
      expect(feasible(ranks, edges), isTrue, reason: '$edges → $ranks');
      expect(
        cost(ranks, edges),
        bruteForce(nodes, edges, nodes * 2),
        reason: '$edges → $ranks',
      );
    }
  });

  test('centers a parent between its children when balancing', () {
    // Aux-graph style: x[parent] pulled toward x[left] and x[right], which
    // must stay 10 apart. Any parent position between them costs the same.
    final edges = <SimplexEdge>[
      (from: 1, to: 2, minLength: 10, weight: 0),
      (from: 3, to: 0, minLength: 0, weight: 1),
      (from: 3, to: 1, minLength: 0, weight: 1),
      (from: 4, to: 0, minLength: 0, weight: 1),
      (from: 4, to: 2, minLength: 0, weight: 1),
    ];
    final ranks = NetworkSimplex.solve(5, edges, balance: true)!;
    expect(ranks[2] - ranks[1], 10);
    expect(ranks[0] - ranks[1], 5);
  });

  test('reports a cycle instead of looping', () {
    expect(
      NetworkSimplex.solve(2, [
        (from: 0, to: 1, minLength: 1, weight: 1),
        (from: 1, to: 0, minLength: 1, weight: 1),
      ]),
      isNull,
    );
  });

  test('ranks each component from zero', () {
    final ranks = NetworkSimplex.solve(4, [
      (from: 0, to: 1, minLength: 2, weight: 1),
      (from: 2, to: 3, minLength: 1, weight: 1),
    ])!;
    expect(ranks, [0, 2, 0, 1]);
  });
}
