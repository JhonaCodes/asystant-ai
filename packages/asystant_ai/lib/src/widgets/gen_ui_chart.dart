import 'package:asystant_core/asystant_core.dart';
import 'package:flutter/material.dart';

import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/widgets/chart_bar_painter.dart';
import 'package:asystant_ai/src/widgets/chart_line_painter.dart';

/// Accessible chart composed into the same cards used for summaries and results.
class GenUiChart extends StatelessWidget {
  const GenUiChart({super.key, required this.chart});

  final AssistantChart chart;

  @override
  Widget build(BuildContext context) {
    if (!chart.isValid) {
      return const SizedBox.shrink();
    }
    final tokens = AsystantTheme.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (chart.kind == AssistantChartKind.line) ...[
          Padding(
            padding: EdgeInsets.all(tokens.spacing),
            child: SizedBox(
              height: tokens.chartHeight,
              child: ExcludeSemantics(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: ChartLinePainter(
                      values: chart.points
                          .map((point) => chart.normalized(point.value))
                          .toList(),
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Divider(),
        ],
        for (final point in chart.points)
          Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spacing / 2),
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: tokens.spacing,
                  children: [
                    Text(point.label, style: theme.textTheme.bodyMedium),
                    Text(
                      chart.valueLabel(point),
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
                if (chart.kind == AssistantChartKind.bar) ...[
                  SizedBox(height: tokens.spacing / 2),
                  ExcludeSemantics(
                    child: SizedBox(
                      height: tokens.spacing / 2,
                      child: ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: CustomPaint(
                          painter: ChartBarPainter(
                            zero: chart.normalized(0),
                            value: chart.normalized(point.value),
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        SizedBox(height: tokens.spacing),
        Text(
          chart.source,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
