import 'package:flutter/material.dart';

import 'package:asystant_ai/src/mermaid/mermaid_edge.dart';
import 'package:asystant_ai/src/mermaid/mermaid_scene.dart';

/// Paints a [MermaidScene] scaled by [scale] from its top-left corner,
/// clipped to the painter's size.
///
/// Layers, back to front: frames, links, link labels, nodes. Geometry and
/// text were prepared by the scene; nothing is measured here.
class MermaidDiagramPainter extends CustomPainter {
  const MermaidDiagramPainter({required this.scene, this.scale = 1});

  final MermaidScene scene;

  final double scale;

  static final Paint _fill = Paint()..style = PaintingStyle.fill;

  static final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    if (!scale.isFinite || scale <= 0) {
      return;
    }
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..scale(scale);
    for (final frame in scene.frames) {
      _paintFrame(canvas, frame);
    }
    for (final edge in scene.edges) {
      _paintEdge(canvas, edge);
    }
    // Titles over the links that enter their frame, on the frame's color.
    for (final frame in scene.frames) {
      final title = frame.title;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          (frame.titleOffset & title.size).inflate(3 * scene.unit),
          Radius.circular(4 * scene.unit),
        ),
        _fill..color = scene.palette.frameFill,
      );
      title.paint(canvas, frame.titleOffset);
    }
    for (final edge in scene.edges) {
      if (edge case MermaidSceneEdge(:final label?, :final chip?)) {
        canvas.drawRRect(chip, _fill..color = scene.palette.labelFill);
        label.paint(
          canvas,
          chip.center - Offset(label.width / 2, label.height / 2),
        );
      }
    }
    for (final node in scene.nodes) {
      _paintNode(canvas, node);
    }
    canvas.restore();
  }

  void _paintFrame(Canvas canvas, MermaidSceneFrame frame) {
    final palette = scene.palette;
    canvas
      ..drawRRect(frame.bounds, _fill..color = palette.frameFill)
      ..drawRRect(
        frame.bounds,
        _stroke
          ..color = palette.frameStroke
          ..strokeWidth = scene.unit,
      );
  }

  void _paintEdge(Canvas canvas, MermaidSceneEdge edge) {
    final color = scene.palette.edge;
    final width = switch (edge.stroke) {
      MermaidLinkStroke.thick => 2.6,
      _ => 1.3,
    };
    canvas
      ..drawPath(
        edge.line,
        _stroke
          ..color = color
          ..strokeWidth = width * scene.unit,
      )
      ..drawPath(edge.heads, _fill..color = color)
      ..drawPath(edge.rings, _fill..color = scene.palette.background)
      ..drawPath(
        edge.rings,
        _stroke
          ..color = color
          ..strokeWidth = 1.3 * scene.unit,
      )
      ..drawPath(edge.crosses, _stroke..strokeWidth = 1.6 * scene.unit);
  }

  void _paintNode(Canvas canvas, MermaidSceneNode node) {
    final palette = scene.palette;
    final stroke = node.decision ? palette.decisionStroke : palette.nodeStroke;
    canvas
      ..drawPath(
        node.outline,
        _fill..color = node.decision ? palette.decisionFill : palette.nodeFill,
      )
      ..drawPath(
        node.outline,
        _stroke
          ..color = stroke
          ..strokeWidth = 1.2 * scene.unit,
      );
    if (node.detail case final detail?) {
      canvas.drawPath(detail, _stroke);
    }
    node.label.paint(canvas, node.labelOffset);
  }

  @override
  bool shouldRepaint(MermaidDiagramPainter oldDelegate) =>
      oldDelegate.scene != scene || oldDelegate.scale != scale;
}
