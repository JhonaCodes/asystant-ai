import 'package:asystant_core/asystant_core.dart';

/// What a chart draws, decided once outside the widget.
extension AssistantChartPresentation on AssistantChart {
  bool get drawsLine => switch (kind) {
    .line => true,
    .bar => false,
  };

  bool get drawsBars => switch (kind) {
    .bar => true,
    .line => false,
  };

  /// Every point's value scaled to 0..1 for the line painter.
  List<double> toNormalizedValues() => [
    for (final point in points) normalized(point.value),
  ];
}
