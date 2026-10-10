import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/mermaid/mermaid_flowchart.dart';
import 'package:asystant_ai/src/mermaid/mermaid_scene.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:asystant_ai/src/widgets/asystant_icon_action.dart';
import 'package:asystant_ai/src/widgets/mermaid_diagram_painter.dart';
import 'package:asystant_ai/src/widgets/mermaid_scene_owner.dart';
import 'package:asystant_ai/src/widgets/mermaid_source_view.dart';

/// A diagram across the whole screen: pan and pinch to zoom, or switch to
/// its source with the action in the bar.
class MermaidDiagramViewer extends StatefulWidget {
  const MermaidDiagramViewer({
    super.key,
    required this.chart,
    required this.source,
    required this.strings,
  });

  /// Opens the viewer over everything, with the caller's theme.
  static Future<void> show(
    BuildContext context, {
    required MermaidFlowchart chart,
    required String source,
    required AsystantStrings strings,
  }) => showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (_) =>
        MermaidDiagramViewer(chart: chart, source: source, strings: strings),
  );

  final MermaidFlowchart chart;

  final String source;

  final AsystantStrings strings;

  @override
  State<MermaidDiagramViewer> createState() => _MermaidDiagramViewerState();
}

class _MermaidDiagramViewerState extends State<MermaidDiagramViewer>
    with MermaidSceneOwner<MermaidDiagramViewer> {
  bool _showsSource = false;

  @override
  MermaidFlowchart get chart => widget.chart;

  @override
  Color sceneBackground(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  void _toggleSource() => setState(() => _showsSource = !_showsSource);

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: AsystantIconAction(
            glyph: AsystantGlyphKind.close,
            tooltip: strings.close,
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(strings.diagram),
          actions: [
            TextButton(
              onPressed: _toggleSource,
              child: Text(
                _showsSource ? strings.showDiagram : strings.showDiagramCode,
              ),
            ),
            SizedBox(width: AsystantTheme.of(context).spacing),
          ],
        ),
        body: switch ((_showsSource, scene)) {
          (false, final scene?) => MermaidDiagramStage(
            scene: scene,
            label: strings.diagramSummary(widget.chart.nodes.length),
          ),
          _ => MermaidSourceView(source: widget.source),
        },
      ),
    );
  }
}

/// The scene fitted to the space it gets (never enlarged), then free to
/// pan and zoom up to well past its natural size.
class MermaidDiagramStage extends StatelessWidget {
  const MermaidDiagramStage({
    super.key,
    required this.scene,
    required this.label,
  });

  final MermaidScene scene;

  /// What a screen reader announces for the diagram.
  final String label;

  /// Zoom past the natural size, for dense diagrams on small screens.
  static const double maxZoom = 3;

  @override
  Widget build(BuildContext context) {
    final margin = AsystantTheme.of(context).padding;
    // Measures the space this view gets, not the device class.
    return LayoutBuilder(
      builder: (context, constraints) {
        final fit = math.min(
          1.0,
          math.min(
            (constraints.maxWidth - 2 * margin) / scene.size.width,
            (constraints.maxHeight - 2 * margin) / scene.size.height,
          ),
        );
        final scale = fit.isFinite && fit > 0 ? fit : 1.0;
        return InteractiveViewer(
          maxScale: math.max(maxZoom, maxZoom / scale),
          child: Center(
            child: Semantics(
              image: true,
              label: label,
              child: CustomPaint(
                size: scene.size * scale,
                painter: MermaidDiagramPainter(scene: scene, scale: scale),
              ),
            ),
          ),
        );
      },
    );
  }
}
