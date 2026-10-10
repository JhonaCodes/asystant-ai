import 'dart:math';

import 'package:asystant_ai/src/mermaid/mermaid_direction.dart';
import 'package:asystant_ai/src/mermaid/mermaid_edge.dart';
import 'package:asystant_ai/src/mermaid/mermaid_flowchart.dart';
import 'package:asystant_ai/src/mermaid/mermaid_flowchart_parser.dart';
import 'package:asystant_ai/src/mermaid/mermaid_node.dart';
import 'package:flutter_test/flutter_test.dart';

/// The session plan keel-server agents send (`logic_mermaid`), verbatim.
const keelPlan = '''
flowchart TD
  A[Inventario con file:line y mapeo de tipos ya decidido] --> B[Cargo.toml: feature sqlite + returning + libsqlite3-sys bundled]
  B --> C[5 migraciones a dialecto SQLite: sin pgcrypto, TEXT para id y JSON]
  E --> F{PRAGMA foreign_keys activo?}
  F -->|No| G[ON DELETE CASCADE roto en silencio] --> E
  F -->|Si| H[WAL una vez antes del pool]
  L -->|Si, H1 confirmado: 503 con base sana| M[readyz con query Diesel count_star] --> N
  Y -->|Si| AA[Entregar sin commitear para auditoria]
''';

MermaidNode nodeOf(MermaidFlowchart chart, String id) =>
    chart.nodes.singleWhere((node) => node.id == id);

List<String> links(MermaidFlowchart chart) => [
  for (final edge in chart.edges) '${edge.from}>${edge.to}',
];

void main() {
  group('the keel session plan', () {
    late MermaidFlowchart chart;

    setUp(() => chart = MermaidFlowchartParser.parse(keelPlan)!);

    test('reads direction, every node once and its label', () {
      expect(chart.direction, MermaidDirection.topDown);
      expect(chart.nodes.map((node) => node.id), [
        'A',
        'B',
        'C',
        'E',
        'F',
        'G',
        'H',
        'L',
        'M',
        'N',
        'Y',
        'AA',
      ]);
      expect(
        nodeOf(chart, 'A').label,
        'Inventario con file:line y mapeo de tipos ya decidido',
      );
      expect(
        nodeOf(chart, 'B').label,
        'Cargo.toml: feature sqlite + returning + libsqlite3-sys bundled',
      );
      expect(nodeOf(chart, 'F').shape, MermaidNodeShape.diamond);
      expect(nodeOf(chart, 'F').label, 'PRAGMA foreign_keys activo?');
      // Referenced without brackets: shown by its id.
      expect(nodeOf(chart, 'E').label, 'E');
      expect(nodeOf(chart, 'E').shape, MermaidNodeShape.rectangle);
    });

    test('keeps chains, pipe labels and the back edge', () {
      expect(links(chart), [
        'A>B',
        'B>C',
        'E>F',
        'F>G',
        'G>E',
        'F>H',
        'L>M',
        'M>N',
        'Y>AA',
      ]);
      final edge = chart.edges.singleWhere((edge) => edge.from == 'L');
      expect(edge.label, 'Si, H1 confirmado: 503 con base sana');
      expect(chart.edges[3].label, 'No');
      // The link after G in the chain has no label of its own.
      expect(chart.edges[4].label, isEmpty);
      expect(
        chart.edges.every((edge) => edge.head == MermaidLinkEnd.arrow),
        isTrue,
      );
    });
  });

  test('reads every link stroke and label form', () {
    final chart = MermaidFlowchartParser.parse('''
graph LR
  A -- plain text --> B
  B -. maybe .-> C
  C == sure ==> D
  D --- E
  E -.- F
  F ===|heavy| G
  G ---> H
  H <--> I
  I --o J
  J --x K
  K ~~~ L
''')!;
    expect(chart.direction, MermaidDirection.leftRight);
    final byFrom = {for (final edge in chart.edges) edge.from: edge};
    expect(byFrom['A']!.label, 'plain text');
    expect(byFrom['A']!.stroke, MermaidLinkStroke.solid);
    expect(byFrom['B']!.label, 'maybe');
    expect(byFrom['B']!.stroke, MermaidLinkStroke.dotted);
    expect(byFrom['C']!.label, 'sure');
    expect(byFrom['C']!.stroke, MermaidLinkStroke.thick);
    expect(byFrom['D']!.head, MermaidLinkEnd.none);
    expect(byFrom['E']!.stroke, MermaidLinkStroke.dotted);
    expect(byFrom['E']!.head, MermaidLinkEnd.none);
    expect(byFrom['F']!.label, 'heavy');
    expect(byFrom['F']!.head, MermaidLinkEnd.none);
    expect(byFrom['G']!.length, 2);
    expect(byFrom['H']!.tail, MermaidLinkEnd.arrow);
    expect(byFrom['H']!.head, MermaidLinkEnd.arrow);
    expect(byFrom['I']!.head, MermaidLinkEnd.circle);
    expect(byFrom['J']!.head, MermaidLinkEnd.cross);
    expect(byFrom['K']!.stroke, MermaidLinkStroke.invisible);
  });

  test('expands & groups, ; statements and quoted labels', () {
    final chart = MermaidFlowchartParser.parse(
      'graph TD;A & B --> C & D;C -->|"x | y"| E["Quoted [text] (here)"];',
    )!;
    expect(links(chart), ['A>C', 'A>D', 'B>C', 'B>D', 'C>E']);
    expect(chart.edges.last.label, 'x | y');
    expect(nodeOf(chart, 'E').label, 'Quoted [text] (here)');
  });

  test('reads every node shape', () {
    final chart = MermaidFlowchartParser.parse('''
flowchart BT
  a[rect] --> b(round) --> c([stadium]) --> d[[sub]] --> e[(db)]
  f((circle)) --> g(((double))) --> h{decide} --> i{{hex}}
  j[/lean right/] --> k[\\lean left\\] --> l[/trap\\] --> m[\\inv/] --> n>flag]
  o[(a) first step]
''')!;
    expect(chart.direction, MermaidDirection.bottomUp);
    expect(chart.nodes.map((node) => node.shape), [
      MermaidNodeShape.rectangle,
      MermaidNodeShape.rounded,
      MermaidNodeShape.stadium,
      MermaidNodeShape.subroutine,
      MermaidNodeShape.cylinder,
      MermaidNodeShape.circle,
      MermaidNodeShape.doubleCircle,
      MermaidNodeShape.diamond,
      MermaidNodeShape.hexagon,
      MermaidNodeShape.leanRight,
      MermaidNodeShape.leanLeft,
      MermaidNodeShape.trapezoid,
      MermaidNodeShape.invertedTrapezoid,
      MermaidNodeShape.asymmetric,
      // `[(` without a closing `)]` is a rectangle whose text starts with `(`.
      MermaidNodeShape.rectangle,
    ]);
    expect(nodeOf(chart, 'o').label, '(a) first step');
    expect(nodeOf(chart, 'j').label, 'lean right');
  });

  test('skips comments, styling and directives; decodes breaks', () {
    final chart = MermaidFlowchartParser.parse('''
%%{init: {"theme": "dark"}}%%
flowchart RL
  %% a comment
  A[First<br/>line] --> B[Tom #quot;the cat#quot; &amp; co]
  classDef hot fill:#f96
  class A hot
  style B fill:#bbf
  linkStyle 0 stroke:#f00
  click A "https://example.com"
  A:::hot --> C
''')!;
    expect(chart.direction, MermaidDirection.rightLeft);
    expect(nodeOf(chart, 'A').label, 'First\nline');
    expect(nodeOf(chart, 'B').label, 'Tom "the cat" & co');
    expect(links(chart), ['A>B', 'A>C']);
  });

  test('assigns nodes to the subgraph that first mentions them', () {
    final chart = MermaidFlowchartParser.parse('''
flowchart TB
  start --> api
  subgraph backend [Backend services]
    api --> db[(Postgres)]
    subgraph jobs
      worker --> db
    end
  end
  subgraph "Client app"
    ui --> start
  end
''')!;
    expect(
      chart.subgraphs.map((group) => (group.id, group.title, group.parent)),
      [
        ('backend', 'Backend services', null),
        ('jobs', 'jobs', 'backend'),
        ('#3', 'Client app', null),
      ],
    );
    expect(nodeOf(chart, 'start').subgraph, '#3');
    expect(nodeOf(chart, 'api').subgraph, 'backend');
    expect(nodeOf(chart, 'db').subgraph, 'backend');
    expect(nodeOf(chart, 'worker').subgraph, 'jobs');
  });

  test('defaults to top-down and keeps self loops', () {
    final chart = MermaidFlowchartParser.parse('graph\nA --> A')!;
    expect(chart.direction, MermaidDirection.topDown);
    expect(links(chart), ['A>A']);
  });

  group('falls back (null) on what it cannot draw faithfully', () {
    for (final source in [
      '',
      '   \n %% only a comment',
      'sequenceDiagram\n  Alice->>Bob: Hi',
      'pie title Pets\n "Dogs" : 386',
      'flowchart XY\n A --> B',
      'flowchart TD',
      'flowchart TD\n A[unclosed --> B',
      'flowchart TD\n A -->',
      'flowchart TD\n A --> B garbage',
      'flowchart TD\n --> B',
      'flowchart TD\n A -->|open label B',
      'flowchart TD\n subgraph one\n A --> B',
      'flowchart TD\n A --> B\n end',
      'flowchart TD\n subgraph one\n A\n end\n one --> B',
      'flowchart TD\n A["unterminated] --> B',
    ]) {
      test(source.replaceAll('\n', r'\n'), () {
        expect(MermaidFlowchartParser.parse(source), isNull);
      });
    }
  });

  test('never throws on mangled input', () {
    final random = Random(7);
    const alphabet = 'AB12 -.=>|[](){}<>/\\"&;:%#~ox\n';
    final samples = [
      for (var cut = 0; cut <= keelPlan.length; cut++)
        keelPlan.substring(0, cut),
      for (var index = 0; index < 400; index++)
        'flowchart TD\n${String.fromCharCodes([for (var char = 0; char < random.nextInt(60); char++) alphabet.codeUnitAt(random.nextInt(alphabet.length))])}',
    ];
    for (final source in samples) {
      expect(() => MermaidFlowchartParser.parse(source), returnsNormally);
    }
  });

  test('refuses diagrams too large to lay out quickly', () {
    final source = StringBuffer('flowchart TD\n');
    for (var index = 0; index < 200; index++) {
      source.writeln('n$index --> n${index + 1}');
    }
    expect(MermaidFlowchartParser.parse(source.toString()), isNull);
  });
}
