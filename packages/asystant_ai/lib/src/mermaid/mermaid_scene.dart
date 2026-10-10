import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'package:asystant_ai/src/mermaid/mermaid_edge.dart';
import 'package:asystant_ai/src/mermaid/mermaid_flowchart.dart';
import 'package:asystant_ai/src/mermaid/mermaid_layout.dart';
import 'package:asystant_ai/src/mermaid/mermaid_node.dart';
import 'package:asystant_ai/src/mermaid/mermaid_palette.dart';
import 'package:asystant_ai/src/mermaid/mermaid_scene_style.dart';
import 'package:asystant_ai/src/mermaid/mermaid_shape_geometry.dart';

/// A node ready to paint, in scene space.
class MermaidSceneNode {
  const MermaidSceneNode({
    required this.bounds,
    required this.outline,
    required this.decision,
    required this.label,
    required this.labelOffset,
    this.detail,
  });

  final Rect bounds;

  final Path outline;

  /// Lines over the outline (subroutine bars, cylinder rim, inner ring).
  final Path? detail;

  /// A diamond: colored apart from the steps.
  final bool decision;

  final TextPainter label;

  final Offset labelOffset;
}

/// A link ready to paint, in scene space.
class MermaidSceneEdge {
  const MermaidSceneEdge({
    required this.line,
    required this.stroke,
    required this.heads,
    required this.rings,
    required this.crosses,
    this.label,
    this.chip,
  });

  /// Already split into dashes when the link is dotted.
  final Path line;

  final MermaidLinkStroke stroke;

  /// Filled arrowheads.
  final Path heads;

  /// `--o` ends: filled with the background, then stroked.
  final Path rings;

  /// `--x` ends, stroked.
  final Path crosses;

  final TextPainter? label;

  /// The chip behind [label]; the label is centered on it.
  final RRect? chip;
}

/// A subgraph frame ready to paint, in scene space.
class MermaidSceneFrame {
  const MermaidSceneFrame({
    required this.bounds,
    required this.title,
    required this.titleOffset,
  });

  final RRect bounds;

  final TextPainter title;

  final Offset titleOffset;
}

/// Everything a flowchart draws, measured, laid out and turned into paths
/// once. The painter only replays it; scaling happens on the canvas.
///
/// Owns its text painters: call [dispose] when it is replaced.
class MermaidScene {
  MermaidScene._({
    required this.size,
    required this.unit,
    required this.palette,
    required this.nodes,
    required this.edges,
    required this.frames,
    required List<TextPainter> text,
  }) : _ownedText = text;

  final Size size;

  /// Text size relative to 14 px; stroke widths follow it.
  final double unit;

  final MermaidPalette palette;

  final List<MermaidSceneNode> nodes;

  final List<MermaidSceneEdge> edges;

  /// Outer frames first, so nested frames paint over them.
  final List<MermaidSceneFrame> frames;

  /// Every text painter measured for the scene, drawn or not.
  final List<TextPainter> _ownedText;

  static const double _nodeLabelWidth = 200;

  static const double _diamondLabelWidth = 150;

  static const double _edgeLabelWidth = 150;

  static const double _titleWidth = 280;

  /// Null when the layout cannot place the chart; the caller shows the
  /// source instead.
  static MermaidScene? build(MermaidFlowchart chart, MermaidSceneStyle style) {
    final unit = style.unit;
    final nodeIndex = {
      for (final (index, node) in chart.nodes.indexed) node.id: index,
    };
    final clusterIndex = {
      for (final (index, subgraph) in chart.subgraphs.indexed)
        subgraph.id: index,
    };
    final nodeLabels = [
      for (final node in chart.nodes)
        _measure(
          node.label,
          style.nodeText,
          style,
          maxWidth:
              (node.shape == MermaidNodeShape.diamond
                  ? _diamondLabelWidth
                  : _nodeLabelWidth) *
              unit,
          maxLines: 8,
        ),
    ];
    final edgeLabels = [
      for (final edge in chart.edges)
        edge.label.isEmpty || edge.stroke == MermaidLinkStroke.invisible
            ? null
            : _measure(
                edge.label,
                style.labelText,
                style,
                maxWidth: _edgeLabelWidth * unit,
                maxLines: 3,
              ),
    ];
    final titles = [
      for (final subgraph in chart.subgraphs)
        _measure(
          subgraph.title,
          style.titleText,
          style,
          maxWidth: _titleWidth * unit,
          maxLines: 1,
        ),
    ];
    final chipPadding = EdgeInsets.symmetric(
      horizontal: 6 * unit,
      vertical: 2.5 * unit,
    );
    final boxes = [
      for (final (index, node) in chart.nodes.indexed)
        MermaidShapeGeometry.boxFor(node.shape, nodeLabels[index].size, unit),
    ];
    final layout = MermaidLayout.compute(
      direction: chart.direction,
      nodes: [
        for (final (index, node) in chart.nodes.indexed)
          _layoutNode(node, boxes[index], clusterIndex, chart, unit),
      ],
      edges: [
        for (final (index, edge) in chart.edges.indexed)
          (
            from: nodeIndex[edge.from]!,
            to: nodeIndex[edge.to]!,
            length: edge.length,
            label: switch (edgeLabels[index]) {
              final label? => chipPadding.inflateSize(label.size),
              null => null,
            },
          ),
      ],
      clusters: [
        for (final (index, subgraph) in chart.subgraphs.indexed)
          (
            parent: subgraph.parent == null
                ? null
                : clusterIndex[subgraph.parent],
            title: titles[index].size,
          ),
      ],
      spacing: const MermaidSpacing().scaled(unit),
    );
    final text = [...nodeLabels, ...edgeLabels.nonNulls, ...titles];
    if (layout == null) {
      for (final painter in text) {
        painter.dispose();
      }
      return null;
    }
    final vertical = chart.direction.isVertical;
    return MermaidScene._(
      size: layout.size,
      unit: unit,
      palette: style.palette,
      nodes: [
        for (final (index, node) in chart.nodes.indexed)
          MermaidSceneNode(
            bounds: layout.nodes[index],
            outline: MermaidShapeGeometry.outline(
              node.shape,
              layout.nodes[index],
              unit,
            ),
            detail: MermaidShapeGeometry.detail(
              node.shape,
              layout.nodes[index],
              unit,
            ),
            decision: node.shape == MermaidNodeShape.diamond,
            label: nodeLabels[index],
            labelOffset: MermaidShapeGeometry.labelOffset(
              node.shape,
              layout.nodes[index],
              nodeLabels[index].size,
              unit,
            ),
          ),
      ],
      edges: [
        for (final (index, edge) in chart.edges.indexed)
          if (edge.stroke != MermaidLinkStroke.invisible)
            _edge(
              edge,
              layout.routes[index],
              edgeLabels[index],
              vertical: vertical,
              unit: unit,
            ),
      ],
      frames: [
        for (final (index, frame) in layout.frames.indexed)
          if (frame != null) _frame(frame, titles[index], unit),
      ],
      text: text,
    );
  }

  static MermaidLayoutNode _layoutNode(
    MermaidNode node,
    Size box,
    Map<String, int> clusterIndex,
    MermaidFlowchart chart,
    double unit,
  ) {
    final ports = MermaidShapeGeometry.ports(
      node.shape,
      box,
      chart.direction,
      unit,
    );
    return (
      size: box,
      cluster: node.subgraph == null ? null : clusterIndex[node.subgraph],
      portSpan: ports.span,
      nearInset: ports.nearInset,
      farInset: ports.farInset,
    );
  }

  static TextPainter _measure(
    String text,
    TextStyle textStyle,
    MermaidSceneStyle style, {
    required double maxWidth,
    required int maxLines,
  }) => TextPainter(
    text: TextSpan(text: text, style: textStyle),
    textAlign: TextAlign.center,
    textDirection: style.textDirection,
    textScaler: style.textScaler,
    maxLines: maxLines,
    ellipsis: '…',
    textWidthBasis: TextWidthBasis.longestLine,
  )..layout(maxWidth: maxWidth);

  static MermaidSceneEdge _edge(
    MermaidEdge edge,
    MermaidRoute route,
    TextPainter? label, {
    required bool vertical,
    required double unit,
  }) {
    final points = [...route.points];
    final thick = edge.stroke == MermaidLinkStroke.thick;
    final headLength = (thick ? 10.5 : 9) * unit;
    final headWidth = (thick ? 5.5 : 4.5) * unit;
    final heads = Path();
    final rings = Path();
    final crosses = Path();
    // The tangent where the line meets each node, pointing into it.
    final endDirection = route.loop
        ? _unit(points[3] - points[2])
        : _flowTangent(points[points.length - 2], points.last, vertical);
    final startDirection = route.loop
        ? -_unit(points[1] - points[0])
        : -_flowTangent(points[0], points[1], vertical);
    points.last = _addEnd(
      edge.head,
      points.last,
      endDirection,
      headLength,
      headWidth,
      unit,
      heads,
      rings,
      crosses,
    );
    points.first = _addEnd(
      edge.tail,
      points.first,
      startDirection,
      headLength,
      headWidth,
      unit,
      heads,
      rings,
      crosses,
    );
    final line = route.loop
        ? (Path()
            ..moveTo(points[0].dx, points[0].dy)
            ..cubicTo(
              points[1].dx,
              points[1].dy,
              points[2].dx,
              points[2].dy,
              points[3].dx,
              points[3].dy,
            ))
        : _flowCurve(points, vertical);
    final chip = route.label;
    return MermaidSceneEdge(
      line: edge.stroke == MermaidLinkStroke.dotted
          ? _dashed(line, 4.5 * unit, 3.5 * unit)
          : line,
      stroke: edge.stroke,
      heads: heads,
      rings: rings,
      crosses: crosses,
      label: label,
      chip: chip == null
          ? null
          : RRect.fromRectAndRadius(chip, Radius.circular(5 * unit)),
    );
  }

  /// Draws [end] at [tip] (pointing along [direction]) and returns where
  /// the line should stop so it does not show through the marker.
  static Offset _addEnd(
    MermaidLinkEnd end,
    Offset tip,
    Offset direction,
    double length,
    double width,
    double unit,
    Path heads,
    Path rings,
    Path crosses,
  ) {
    final side = Offset(-direction.dy, direction.dx);
    switch (end) {
      case MermaidLinkEnd.none:
        return tip;
      case MermaidLinkEnd.arrow:
        final base = tip - direction * length;
        heads.addPolygon([
          tip,
          base + side * width,
          base + direction * (length * .2),
          base - side * width,
        ], true);
        return base + direction * (length * .3);
      case MermaidLinkEnd.circle:
        final radius = 3.8 * unit;
        final center = tip - direction * radius;
        rings.addOval(Rect.fromCircle(center: center, radius: radius));
        return center - direction * radius;
      case MermaidLinkEnd.cross:
        final arm = 4 * unit;
        final center = tip - direction * arm;
        final a = _unit(direction + side) * arm;
        final b = _unit(direction - side) * arm;
        crosses
          ..moveTo((center - a).dx, (center - a).dy)
          ..lineTo((center + a).dx, (center + a).dy)
          ..moveTo((center - b).dx, (center - b).dy)
          ..lineTo((center + b).dx, (center + b).dy);
        return center - direction * arm;
    }
  }

  static Offset _unit(Offset offset) =>
      offset.distance == 0 ? const Offset(0, 1) : offset / offset.distance;

  /// Direction of travel from [from] to [to] along the flow axis.
  static Offset _flowTangent(Offset from, Offset to, bool vertical) {
    final delta = vertical ? to.dy - from.dy : to.dx - from.dx;
    if (delta == 0) {
      return _unit(to - from);
    }
    return vertical ? Offset(0, delta.sign) : Offset(delta.sign, 0);
  }

  /// Joins the points with curves that leave and enter each point along
  /// the flow, so a route bends smoothly and meets nodes square.
  static Path _flowCurve(List<Offset> points, bool vertical) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      final from = points[index - 1];
      final to = points[index];
      if (vertical) {
        final half = (to.dy - from.dy) / 2;
        path.cubicTo(
          from.dx,
          from.dy + half,
          to.dx,
          to.dy - half,
          to.dx,
          to.dy,
        );
      } else {
        final half = (to.dx - from.dx) / 2;
        path.cubicTo(
          from.dx + half,
          from.dy,
          to.dx - half,
          to.dy,
          to.dx,
          to.dy,
        );
      }
    }
    return path;
  }

  static Path _dashed(Path source, double dash, double gap) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        dashed.addPath(metric.extractPath(distance, end), Offset.zero);
        distance = end + gap;
      }
    }
    return dashed;
  }

  static MermaidSceneFrame _frame(
    MermaidFrame frame,
    TextPainter title,
    double unit,
  ) {
    if (title.width > frame.title.width) {
      title.layout(maxWidth: frame.title.width);
    }
    return MermaidSceneFrame(
      bounds: RRect.fromRectAndRadius(frame.bounds, Radius.circular(8 * unit)),
      title: title,
      titleOffset: frame.title.topLeft,
    );
  }

  void dispose() {
    for (final painter in _ownedText) {
      painter.dispose();
    }
  }
}
