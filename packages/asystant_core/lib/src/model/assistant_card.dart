import 'package:asystant_core/src/model/assistant_chart.dart';
import 'package:asystant_core/src/model/assistant_value.dart';

/// Supported presentations for read-only summaries, user choices and action results.
enum AssistantCardKind { summary, entity, selection, permission, result }

/// A structured presentation returned by a local tool, never executable UI code.
class AssistantCard extends AssistantValue {
  const AssistantCard({
    required this.title,
    this.body = '',
    this.kind = .summary,
    this.options = const [],
    this.chart,
  });

  final String title;

  final String body;

  final AssistantCardKind kind;

  /// Stable option values; application tools may map these to domain identifiers.
  final List<String> options;

  /// Optional data visualization composed into any card presentation.
  final AssistantChart? chart;

  AssistantCard copyWith({
    String? title,
    String? body,
    AssistantCardKind? kind,
    List<String>? options,
    AssistantChart? chart,
    bool clearChart = false,
  }) => AssistantCard(
    chart: clearChart ? null : chart ?? this.chart,
    title: title ?? this.title,
    body: body ?? this.body,
    kind: kind ?? this.kind,
    options: List.unmodifiable(options ?? this.options),
  );

  factory AssistantCard.fromJson(Map<String, Object?> json) => AssistantCard(
    chart: json['chart'] == null
        ? null
        : AssistantChart.fromJson(json['chart'] as Map<String, Object?>),
    title: json['title'] as String,
    body: json['body'] as String,
    kind: AssistantCardKind.values.byName(json['kind'] as String),
    options: List.unmodifiable(
      (json['options'] as List<Object?>).cast<String>(),
    ),
  );

  @override
  Map<String, Object?> toJson() => {
    if (chart case final chart?) 'chart': chart.toJson(),
    'title': title,
    'body': body,
    'kind': kind.name,
    'options': options,
  };
}
