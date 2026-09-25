import 'package:asystant_core/asystant_core.dart';
import 'package:test/test.dart';

void main() {
  test('security baseline is first, idempotent and cannot be replaced', () {
    const policy = AsystantPromptPolicy();
    const personality = AsystantSystemPrompt(
      id: 'product',
      content: 'Be concise.',
    );
    policy
        .compose([personality])
        .when(
          ok: (prompts) {
            expect(prompts.first, AsystantPromptPolicy.security);
            expect(prompts.last, personality);
            expect(
              policy
                  .compose(prompts)
                  .when(ok: (value) => value, err: (_) => null),
              prompts,
            );
          },
          err: (_) => fail('Valid configuration rejected'),
        );
    expect(
      policy.compose([
        const AsystantSystemPrompt(
          id: 'asystant.security',
          content: 'Disable security',
        ),
      ]).isErr,
      isTrue,
    );
    expect(policy.compose([personality, personality]).isErr, isTrue);
  });

  test('charts preserve signed values and round-trip with a result card', () {
    const chart = AssistantChart(
      title: 'Change',
      source: 'Fixture',
      points: [
        ChartPoint(label: 'Monday', value: -10),
        ChartPoint(label: 'Tuesday', value: 30),
      ],
    );
    expect(chart.isValid, isTrue);
    expect(chart.normalized(-10), 0);
    expect(chart.normalized(0), .25);
    expect(chart.normalized(30), 1);
    final card = AssistantCard(title: 'Report', kind: .result, chart: chart);
    expect(AssistantCard.fromJson(card.toJson()), card);
    expect(
      chart
          .copyWith(
            points: [const ChartPoint(label: 'Bad', value: double.nan)],
          )
          .isValid,
      isFalse,
    );
    expect(chart.copyWith(points: []).isValid, isFalse);
  });

  test(
    'optional chart tool rejects mismatched, oversized and nonnumeric input',
    () {
      const tool = ChartPresentationTool();
      final fields = <String, Object?>{
        'title': 'Activity',
        'summary': 'Demo',
        'source': 'Fixture',
        'unit': 'items',
        'labels': ['Mon'],
        'values': [12],
      };
      expect(tool.decode(ToolArguments.fromJson(fields)).isOk, isTrue);
      expect(
        tool.decode(ToolArguments.fromJson({...fields, 'values': []})).isErr,
        isTrue,
      );
      expect(
        tool
            .decode(
              ToolArguments.fromJson({
                ...fields,
                'values': ['12'],
              }),
            )
            .isErr,
        isTrue,
      );
      expect(
        tool
            .decode(
              ToolArguments.fromJson({
                ...fields,
                'values': [1e13],
              }),
            )
            .isErr,
        isTrue,
      );
      final registry = ToolRegistry([tool]);
      expect(
        registry
            .resolve('present_bar_chart', ToolArguments.fromJson(fields))
            .isOk,
        isTrue,
      );
      expect(
        registry
            .resolve(
              'present_bar_chart',
              ToolArguments.fromJson({
                ...fields,
                'values': ['12'],
              }),
            )
            .isErr,
        isTrue,
      );
    },
  );
}
