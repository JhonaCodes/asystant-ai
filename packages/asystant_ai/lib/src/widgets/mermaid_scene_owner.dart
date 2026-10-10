import 'package:flutter/widgets.dart';

import 'package:asystant_ai/src/mermaid/mermaid_flowchart.dart';
import 'package:asystant_ai/src/mermaid/mermaid_scene.dart';
import 'package:asystant_ai/src/mermaid/mermaid_scene_style.dart';

/// Builds the [scene] of a widget's [chart] with the surrounding theme, and
/// rebuilds it only when the chart or the theme changes. The scene owns
/// measured text, so it is disposed when replaced and with the widget.
mixin MermaidSceneOwner<T extends StatefulWidget> on State<T> {
  MermaidScene? _scene;

  MermaidSceneStyle? _style;

  MermaidFlowchart? _chart;

  MermaidFlowchart get chart;

  /// The surface the diagram is painted on; node tints are mixed over it.
  Color sceneBackground(BuildContext context);

  /// Null when the chart could not be laid out: show its source instead.
  MermaidScene? get scene => _scene;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshScene();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshScene();
  }

  void _refreshScene() {
    final style = MermaidSceneStyle.of(
      context,
      background: sceneBackground(context),
    );
    if (style == _style && chart == _chart) {
      return;
    }
    _scene?.dispose();
    _scene = MermaidScene.build(chart, style);
    _style = style;
    _chart = chart;
  }

  @override
  void dispose() {
    _scene?.dispose();
    super.dispose();
  }
}
