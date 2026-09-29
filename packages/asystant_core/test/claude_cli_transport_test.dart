import 'dart:convert';

import 'package:asystant_core/asystant_core.dart';
import 'package:test/test.dart';

/// Replays recorded CLI output instead of starting `claude`.
class _RecordedLauncher implements ClaudeCliLauncher {
  _RecordedLauncher(this.stdout);

  final List<Map<String, Object?>> stdout;

  final List<ClaudeCliInvocation> invocations = [];

  @override
  Future<Result<ClaudeCliProcess, AssistantFailure>> start(
    ClaudeCliInvocation invocation,
  ) async {
    invocations.add(invocation);
    return Ok(
      ClaudeCliProcess(
        stdoutLines: Stream.fromIterable(stdout.map(jsonEncode)),
        stderrLines: const Stream.empty(),
        exitCode: Future.value(0),
        kill: () {},
      ),
    );
  }
}

Map<String, Object?> _delta(String text) => {
  'type': 'stream_event',
  'event': {
    'type': 'content_block_delta',
    'index': 0,
    'delta': {'type': 'text_delta', 'text': text},
  },
  'parent_tool_use_id': null,
};

const _echo = ToolDefinition(
  name: 'echo',
  description: 'Repeats the given text.',
  fields: [
    ToolField(
      name: 'text',
      description: 'Text to repeat.',
      kind: ToolFieldKind.string,
    ),
  ],
);

void main() {
  test('a recorded stream-json run becomes text, one tool call and a '
      'completed message', () async {
    // The call block arrives split across deltas, as the CLI streams it.
    const reply =
        'Voy a repetirlo.\n'
        '<tool_call>{"name": "echo", "arguments": {"text": "hola"}}'
        '</tool_call>';
    final launcher = _RecordedLauncher([
      {'type': 'system', 'subtype': 'init', 'tools': <Object?>[]},
      _delta('Voy a repetirlo.\n<tool'),
      _delta('_call>{"name": "echo", "arguments": {"text": "hola"}}</tool_'),
      _delta('call>'),
      {
        'type': 'assistant',
        'message': {
          'role': 'assistant',
          'content': [
            {'type': 'text', 'text': reply},
          ],
        },
        'parent_tool_use_id': null,
      },
      {
        'type': 'result',
        'subtype': 'success',
        'is_error': false,
        'stop_reason': 'end_turn',
        'result': reply,
        'usage': {
          'input_tokens': 10,
          'cache_creation_input_tokens': 5,
          'cache_read_input_tokens': 100,
          'output_tokens': 20,
        },
      },
    ]);
    final transport = ClaudeCliTransport(launcher: launcher);
    addTearDown(transport.dispose);
    final models = await transport.initialize(
      tools: const [_echo],
      prompts: const [],
      models: const [],
    );
    expect(models.data, ClaudeCliTransport.defaultModels);

    final events = await transport
        .infer(
          messages: const [
            AssistantMessage(role: MessageRole.user, content: 'Repite hola'),
          ],
          model: 'sonnet',
          requestId: 't1-0',
        )
        .toList();

    expect(
      events.whereType<TextDelta>().map((event) => event.text).join(),
      'Voy a repetirlo.\n',
    );
    expect(events.whereType<InferenceFailed>(), isEmpty);
    expect(events.sublist(events.length - 2), [
      const UsageReported(TokenUsage(promptTokens: 115, completionTokens: 20)),
      InferenceCompleted(
        AssistantMessage(
          role: MessageRole.assistant,
          content: 'Voy a repetirlo.',
          calls: [
            ToolCall(
              id: 'call_t1-0_0',
              name: 'echo',
              arguments: ToolArguments.fromJson(const {'text': 'hola'}),
            ),
          ],
        ),
      ),
    ]);

    final invocation = launcher.invocations.single;
    // The CLI's own tools are off, and no prompt text is on the command line.
    expect(invocation.arguments, containsAllInOrder(['--tools', '']));
    expect(invocation.arguments.any((a) => a.contains('Repite')), isFalse);
    expect(invocation.prompt, contains('Repite hola'));
    expect(invocation.systemPrompt, contains('"name":"echo"'));
  });

  test(
    'a missing binary fails the inference and says what to install',
    () async {
      final transport = ClaudeCliTransport(executable: '/nonexistent/claude');
      addTearDown(transport.dispose);
      await transport.initialize(
        tools: const [],
        prompts: const [],
        models: const [],
      );

      final events = await transport
          .infer(
            messages: const [
              AssistantMessage(role: MessageRole.user, content: 'Hola'),
            ],
            model: 'sonnet',
            requestId: 't1-0',
          )
          .toList();

      final failure = (events.single as InferenceFailed).failure;
      expect(failure.code, FailureCode.unavailable);
      expect(
        failure.detail,
        contains('npm install -g @anthropic-ai/claude-code'),
      );
    },
  );
}
