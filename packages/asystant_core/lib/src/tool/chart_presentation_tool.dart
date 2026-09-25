import 'package:asystant_core/asystant_core.dart';

/// Optional local visualization tool; register it explicitly in builtInTools.
/// Prefer charts returned directly by application tools for authoritative data.
class ChartPresentationTool extends TypedAsystantTool<AssistantCard> {
  const ChartPresentationTool({this.kind = .bar});

  final AssistantChartKind kind;

  @override
  bool get requiresConfirmation => false;

  @override
  ToolDefinition get definition => ToolDefinition(
    name: 'present_${kind.name}_chart',
    description:
        'Show a chart using only supplied or authorized tool data. '
        'Never invent measurements. Include the source, period and sampling limits.',
    fields: const [
      ToolField(name: 'title', description: 'Chart title', kind: .string),
      ToolField(
        name: 'summary',
        description: 'Concise factual summary',
        kind: .string,
      ),
      ToolField(
        name: 'source',
        description: 'Data source, period and completeness',
        kind: .string,
      ),
      ToolField(name: 'unit', description: 'Measurement unit', kind: .string),
      ToolField(
        name: 'labels',
        description: 'One label per measurement, at most 24',
        kind: .strings,
      ),
      ToolField(
        name: 'values',
        description: 'Finite measurements matching labels',
        kind: .numbers,
      ),
    ],
  );

  @override
  Result<AssistantCard, AssistantFailure> decode(ToolArguments arguments) {
    try {
      final labels = arguments.strings('labels');
      final values = arguments.numbers('values');
      if (labels.length != values.length || values.length > 24) {
        return Err(const AssistantFailure(.invalidTool));
      }
      final chart = AssistantChart(
        title: arguments.string('title'),
        source: arguments.string('source'),
        unit: arguments.string('unit'),
        kind: kind,
        points: List.unmodifiable(
          List.generate(
            labels.length,
            (index) => ChartPoint(label: labels[index], value: values[index]),
          ),
        ),
      );
      if (!chart.isValid || arguments.string('summary').length > 2000) {
        return Err(const AssistantFailure(.invalidTool));
      }
      return Ok(
        AssistantCard(
          title: chart.title,
          body: arguments.string('summary'),
          chart: chart,
        ),
      );
    } on FormatException {
      return Err(const AssistantFailure(.invalidTool));
    } on TypeError {
      return Err(const AssistantFailure(.invalidTool));
    }
  }

  @override
  Future<Result<AssistantCard, AssistantFailure>> previewInput(
    AssistantCard input,
  ) async => Ok(input);

  @override
  Future<Result<ToolOutcome, AssistantFailure>> executeInput(
    AssistantCard input,
    ToolContext context,
  ) async {
    context.checkCanceled();
    return Ok(
      ToolOutcome(
        modelContent: 'Chart shown; no application data changed.',
        card: input,
      ),
    );
  }
}
