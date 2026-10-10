import 'dart:math';
import 'dart:ui';

import 'package:asystant_ai/src/mermaid/mermaid_direction.dart';
import 'package:asystant_ai/src/mermaid/mermaid_edge.dart';
import 'package:asystant_ai/src/mermaid/mermaid_flowchart.dart';
import 'package:asystant_ai/src/mermaid/mermaid_flowchart_parser.dart';
import 'package:asystant_ai/src/mermaid/mermaid_layout.dart';
import 'package:asystant_ai/src/mermaid/mermaid_node.dart';
import 'package:asystant_ai/src/mermaid/mermaid_preview_fit.dart';
import 'package:asystant_ai/src/mermaid/mermaid_subgraph.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mermaid_flowchart_parser_test.dart' show keelPlan;

/// Lays a chart out with box sizes derived from label length, so geometry
/// can be checked without fonts.
MermaidLayoutResult layOut(MermaidFlowchart chart) {
  final clusters = [for (final subgraph in chart.subgraphs) subgraph.id];
  final nodes = [for (final node in chart.nodes) node.id];
  return MermaidLayout.compute(
    direction: chart.direction,
    nodes: [
      for (final node in chart.nodes)
        (
          size: Size(40 + 6.0 * node.label.length.clamp(0, 30), 36),
          cluster: node.subgraph == null
              ? null
              : clusters.indexOf(node.subgraph!),
          portSpan: 20,
          nearInset: 0,
          farInset: 0,
        ),
    ],
    edges: [
      for (final edge in chart.edges)
        (
          from: nodes.indexOf(edge.from),
          to: nodes.indexOf(edge.to),
          length: edge.length,
          label: edge.label.isEmpty
              ? null
              : Size(8.0 * edge.label.length.clamp(0, 18), 20),
        ),
    ],
    clusters: [
      for (final subgraph in chart.subgraphs)
        (
          parent: subgraph.parent == null
              ? null
              : clusters.indexOf(subgraph.parent!),
          title: Size(7.0 * subgraph.title.length, 16),
        ),
    ],
  )!;
}

bool touches(Offset point, Rect box) => box.inflate(.5).contains(point);

void expectSound(MermaidFlowchart chart, MermaidLayoutResult layout) {
  final ids = [for (final node in chart.nodes) node.id];
  final scene = Offset.zero & layout.size;
  for (var a = 0; a < layout.nodes.length; a++) {
    expect(scene.contains(layout.nodes[a].center), isTrue);
    for (var b = a + 1; b < layout.nodes.length; b++) {
      expect(
        layout.nodes[a].overlaps(layout.nodes[b]),
        isFalse,
        reason: '${ids[a]} overlaps ${ids[b]}',
      );
    }
  }
  for (final (index, edge) in chart.edges.indexed) {
    final route = layout.routes[index];
    final from = layout.nodes[ids.indexOf(edge.from)];
    final to = layout.nodes[ids.indexOf(edge.to)];
    expect(touches(route.points.first, from), isTrue, reason: '$edge start');
    expect(touches(route.points.last, to), isTrue, reason: '$edge end');
    // Bends stay clear of every box; labels too.
    for (final point in route.points.sublist(1, route.points.length - 1)) {
      if (route.loop) {
        continue;
      }
      for (final (other, box) in layout.nodes.indexed) {
        expect(
          box.deflate(.5).contains(point),
          isFalse,
          reason: '$edge bends inside ${ids[other]}',
        );
      }
    }
    if (route.label case final label?) {
      for (final (other, box) in layout.nodes.indexed) {
        expect(
          label.overlaps(box),
          isFalse,
          reason: 'label of $edge on ${ids[other]}',
        );
      }
    }
  }
}

void main() {
  test('the keel plan: sound geometry, back edge routed around', () {
    final chart = MermaidFlowchartParser.parse(keelPlan)!;
    final layout = layOut(chart);
    expectSound(chart, layout);
    final ids = [for (final node in chart.nodes) node.id];
    Rect box(String id) => layout.nodes[ids.indexOf(id)];
    // The flow goes down; the back edge G → E goes up, from G's top to
    // E's bottom.
    expect(box('A').center.dy, lessThan(box('B').center.dy));
    expect(box('F').center.dy, lessThan(box('G').center.dy));
    final back = layout.routes[chart.edges.indexWhere((e) => e.from == 'G')];
    expect(back.points.first.dy, closeTo(box('G').top, .5));
    expect(back.points.last.dy, closeTo(box('E').bottom, .5));
    // The decision sits between its two branches.
    expect(box('F').center.dx, greaterThan(box('G').center.dx));
    expect(box('F').center.dx, lessThan(box('H').center.dx));
  });

  test('is deterministic', () {
    final chart = MermaidFlowchartParser.parse(keelPlan)!;
    final first = layOut(chart);
    final second = layOut(chart);
    expect(second.size, first.size);
    expect(second.nodes, first.nodes);
    for (var index = 0; index < first.routes.length; index++) {
      expect(second.routes[index].points, first.routes[index].points);
    }
  });

  test('every direction keeps the flow on its axis', () {
    for (final (keyword, direction) in [
      ('TD', MermaidDirection.topDown),
      ('BT', MermaidDirection.bottomUp),
      ('LR', MermaidDirection.leftRight),
      ('RL', MermaidDirection.rightLeft),
    ]) {
      final chart = MermaidFlowchartParser.parse(
        'flowchart $keyword\n  A[One] -->|go| B{Two?} -->|yes| C[Three]\n  B -->|no| A\n  C --> C',
      )!;
      expect(chart.direction, direction);
      final layout = layOut(chart);
      expectSound(chart, layout);
      final a = layout.nodes[0].center;
      final c = layout.nodes[2].center;
      final advance = switch (direction) {
        MermaidDirection.topDown => c.dy - a.dy,
        MermaidDirection.bottomUp => a.dy - c.dy,
        MermaidDirection.leftRight => c.dx - a.dx,
        MermaidDirection.rightLeft => a.dx - c.dx,
      };
      expect(advance, greaterThan(0), reason: keyword);
    }
  });

  test('subgraph frames hold their nodes and keep the others out', () {
    final chart = MermaidFlowchartParser.parse('''
flowchart TB
  start --> api
  subgraph backend [Backend services]
    api --> auth{Authorized?}
    auth -->|yes| svc
    subgraph data
      svc --> db[(Postgres)]
      svc --> cache[(Redis)]
    end
  end
  auth -->|no| deny
  subgraph client [Client app]
    ui --> start
  end
  db --> report
''')!;
    final layout = layOut(chart);
    expectSound(chart, layout);
    final groups = [for (final subgraph in chart.subgraphs) subgraph.id];
    for (final (index, subgraph) in chart.subgraphs.indexed) {
      final frame = layout.frames[index]!;
      bool inside(String? group) {
        for (var current = group; current != null;) {
          if (current == subgraph.id) {
            return true;
          }
          current = chart.subgraphs[groups.indexOf(current)].parent;
        }
        return false;
      }

      for (final (node, box) in layout.nodes.indexed) {
        final member = inside(chart.nodes[node].subgraph);
        expect(
          member
              ? frame.bounds.contains(box.center)
              : !frame.bounds.overlaps(box),
          isTrue,
          reason: '${chart.nodes[node].id} vs ${subgraph.id}',
        );
      }
      expect(frame.bounds.contains(frame.title.center), isTrue);
    }
    // Sibling frames do not overlap; a nested frame sits inside its parent.
    expect(
      layout.frames[0]!.bounds.overlaps(layout.frames[2]!.bounds),
      isFalse,
    );
    expect(
      layout.frames[0]!.bounds.expandToInclude(layout.frames[1]!.bounds),
      layout.frames[0]!.bounds,
    );
  });

  test('random charts with cycles, loops and nested frames stay sound', () {
    final random = Random(11);
    for (var round = 0; round < 80; round++) {
      final count = 2 + random.nextInt(30);
      final subgraphs = [
        const MermaidSubgraph(id: 's0', title: 'Outer'),
        const MermaidSubgraph(id: 's1', title: 'Inner', parent: 's0'),
        const MermaidSubgraph(id: 's2', title: 'Side'),
      ];
      final chart = MermaidFlowchart(
        direction: MermaidDirection.values[round % 4],
        nodes: [
          for (var node = 0; node < count; node++)
            MermaidNode(
              id: 'n$node',
              label: 'step $node' * (1 + random.nextInt(3)),
              subgraph: switch (random.nextInt(6)) {
                0 => 's0',
                1 => 's1',
                2 => 's2',
                _ => null,
              },
            ),
        ],
        edges: [
          for (var edge = 0; edge < count + random.nextInt(count); edge++)
            MermaidEdge(
              from: 'n${random.nextInt(count)}',
              to: 'n${random.nextInt(count)}',
              label: random.nextBool() ? '' : 'if $edge',
              length: 1 + random.nextInt(2),
            ),
        ],
        subgraphs: subgraphs,
      );
      final layout = layOut(chart);
      expectSound(chart, layout);
      for (final (index, frame) in layout.frames.indexed) {
        for (final (node, box) in layout.nodes.indexed) {
          final group = chart.nodes[node].subgraph;
          final member =
              group == subgraphs[index].id || (index == 0 && group == 's1');
          if (frame != null && !member) {
            expect(frame.bounds.overlaps(box), isFalse, reason: 'round $round');
          }
        }
      }
    }
  });

  test('a diagram in a message is scaled to its width, never below 60 %', () {
    final narrow = MermaidPreviewFit.of(
      const Size(600, 300),
      maxWidth: 400,
      maxHeight: 420,
    );
    expect(narrow.scale, closeTo(400 / 600, 1e-9));
    expect(narrow.size, const Size(400, 200));
    expect(narrow.clipsWidth || narrow.clipsHeight, isFalse);

    final wide = MermaidPreviewFit.of(
      const Size(1600, 900),
      maxWidth: 320,
      maxHeight: 420,
    );
    expect(wide.scale, MermaidPreviewFit.defaultMinScale);
    expect(wide.size, const Size(320, 420));
    expect(wide.clipsWidth && wide.clipsHeight, isTrue);

    final small = MermaidPreviewFit.of(
      const Size(200, 120),
      maxWidth: 400,
      maxHeight: 420,
    );
    expect(small.scale, 1);
    expect(small.size, const Size(200, 120));
  });
}
