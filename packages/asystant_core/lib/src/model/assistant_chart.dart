import 'dart:math' as math;

import 'package:asystant_core/src/model/assistant_value.dart';
import 'package:asystant_core/src/model/chart_point.dart';

/// Supported deterministic chart presentations.
enum AssistantChartKind { bar, line }

/// A bounded, labeled data series for summaries, entity cards and results.
///
/// [source] should describe the real data origin, period and sampling limits.
/// Chart data is presentation data, never executable widget instructions.
class AssistantChart extends AssistantValue {
  const AssistantChart({
    required this.title,
    required this.points,
    required this.source,
    this.unit = '',
    this.kind = AssistantChartKind.bar,
  });

  final String title;

  final List<ChartPoint> points;

  final String source;

  final String unit;

  final AssistantChartKind kind;

  /// Bounds both render cost and numeric geometry, including untrusted input.
  bool get isValid =>
      title.trim().isNotEmpty &&
      title.length <= 120 &&
      source.trim().isNotEmpty &&
      source.length <= 500 &&
      unit.length <= 40 &&
      points.isNotEmpty &&
      points.length <= 24 &&
      points.every(
        (point) =>
            point.label.trim().isNotEmpty &&
            point.label.length <= 100 &&
            point.value.isFinite &&
            point.value.abs() <= 1e12,
      );

  /// The domain includes zero so negative values and magnitudes stay truthful.
  double get minimum => points.fold(0, (v, p) => math.min(v, p.value));

  double get maximum => points.fold(0, (v, p) => math.max(v, p.value));

  double get span => maximum == minimum ? 1 : maximum - minimum;

  double normalized(double value) => (value - minimum) / span;

  String valueLabel(ChartPoint point) =>
      '${point.value == point.value.roundToDouble() ? point.value.toStringAsFixed(0) : point.value.toString()}${unit.isEmpty ? '' : ' $unit'}';

  AssistantChart copyWith({
    String? title,
    List<ChartPoint>? points,
    String? source,
    String? unit,
    AssistantChartKind? kind,
  }) => AssistantChart(
    title: title ?? this.title,
    points: List.unmodifiable(points ?? this.points),
    source: source ?? this.source,
    unit: unit ?? this.unit,
    kind: kind ?? this.kind,
  );

  factory AssistantChart.fromJson(Map<String, Object?> json) => AssistantChart(
    title: json['title'] as String,
    source: json['source'] as String,
    unit: json['unit'] as String? ?? '',
    kind: AssistantChartKind.values.byName(json['kind'] as String),
    points: List.unmodifiable(
      (json['points'] as List<Object?>).map(
        (point) => ChartPoint.fromJson(point as Map<String, Object?>),
      ),
    ),
  );

  @override
  Map<String, Object?> toJson() => {
    'title': title,
    'source': source,
    'unit': unit,
    'kind': kind.name,
    'points': points.map((point) => point.toJson()).toList(),
  };
}
