import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/mermaid/mermaid_flowchart.dart';
import 'package:asystant_ai/src/mermaid/mermaid_preview_fit.dart';
import 'package:asystant_ai/src/mermaid/mermaid_scene.dart';
import 'package:asystant_ai/src/theme/asystant_metrics.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:asystant_ai/src/widgets/mermaid_diagram_painter.dart';
import 'package:asystant_ai/src/widgets/mermaid_diagram_viewer.dart';
import 'package:asystant_ai/src/widgets/mermaid_scene_owner.dart';
import 'package:asystant_ai/src/widgets/mermaid_source_block.dart';

/// A flowchart inside a message: a card sized to the diagram that opens the
/// full view on a tap.
class MermaidDiagramCard extends StatefulWidget {
  const MermaidDiagramCard({
    super.key,
    required this.chart,
    required this.source,
    required this.strings,
  });

  final MermaidFlowchart chart;

  final String source;

  final AsystantStrings strings;

  @override
  State<MermaidDiagramCard> createState() => _MermaidDiagramCardState();
}

class _MermaidDiagramCardState extends State<MermaidDiagramCard>
    with MermaidSceneOwner<MermaidDiagramCard> {
  @override
  MermaidFlowchart get chart => widget.chart;

  @override
  Color sceneBackground(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerLowest;

  void _open() => unawaited(
    MermaidDiagramViewer.show(
      context,
      chart: widget.chart,
      source: widget.source,
      strings: widget.strings,
    ),
  );

  @override
  Widget build(BuildContext context) => switch (scene) {
    final scene? => _DiagramCardFrame(
      scene: scene,
      strings: widget.strings,
      steps: widget.chart.nodes.length,
      background: sceneBackground(context),
      onOpen: _open,
    ),
    null => MermaidSourceBlock(source: widget.source),
  };
}

class _DiagramCardFrame extends StatelessWidget {
  const _DiagramCardFrame({
    required this.scene,
    required this.strings,
    required this.steps,
    required this.background,
    required this.onOpen,
  });

  final MermaidScene scene;

  final AsystantStrings strings;

  final int steps;

  final Color background;

  final VoidCallback onOpen;

  /// Room for the card's header when the diagram itself is narrower.
  static const double _minContentWidth = 140;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final padding = AsystantMetrics.of(context).cardPadding;
    final maxHeight = AsystantTheme.of(context).diagramMaxHeight;
    final radius = BorderRadius.circular(
      AsystantMetrics.of(context).bubbleRadius,
    );
    // Measures the width this message gives the card, not the device class.
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - 2 * padding;
        final fit = MermaidPreviewFit.of(
          scene.size,
          maxWidth: available,
          maxHeight: maxHeight,
        );
        return Semantics(
          button: true,
          label: strings.diagramSummary(steps),
          onTapHint: strings.openDiagram,
          excludeSemantics: true,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onOpen,
              borderRadius: radius,
              child: Ink(
                decoration: BoxDecoration(
                  color: background,
                  border: Border.all(color: colors.outlineVariant),
                  borderRadius: radius,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    padding * .6,
                    padding,
                    padding,
                  ),
                  child: SizedBox(
                    width: math.min(
                      available,
                      math.max(fit.size.width, _minContentWidth),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DiagramCardHeader(label: strings.diagram),
                        SizedBox(height: padding * .5),
                        Center(
                          child: _DiagramPreview(
                            scene: scene,
                            fit: fit,
                            background: background,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DiagramCardHeader extends StatelessWidget {
  const _DiagramCardHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox.square(
          dimension: 16,
          child: FittedBox(
            child: AsystantGlyph(
              AsystantGlyphKind.expand,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// The scaled diagram, faded out where it is clipped.
class _DiagramPreview extends StatelessWidget {
  const _DiagramPreview({
    required this.scene,
    required this.fit,
    required this.background,
  });

  final MermaidScene scene;

  final MermaidPreviewFit fit;

  final Color background;

  static const double _fade = 40;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    size: fit.size,
    child: Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: MermaidDiagramPainter(scene: scene, scale: fit.scale),
            ),
          ),
        ),
        if (fit.clipsHeight)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: math.min(_fade, fit.size.height / 3),
            child: _Fade(color: background, end: Alignment.bottomCenter),
          ),
        if (fit.clipsWidth)
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: math.min(_fade, fit.size.width / 3),
            child: _Fade(color: background, end: Alignment.centerRight),
          ),
      ],
    ),
  );
}

/// Transparent to [color] towards [end]: the diagram continues past it.
class _Fade extends StatelessWidget {
  const _Fade({required this.color, required this.end});

  final Color color;

  final Alignment end;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: -end,
          end: end,
          colors: [color.withValues(alpha: 0), color],
        ),
      ),
    ),
  );
}
