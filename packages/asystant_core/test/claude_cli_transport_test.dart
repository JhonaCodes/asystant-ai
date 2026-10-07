import 'dart:convert';
import 'dart:typed_data';

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

  /// As if the binary could not answer short commands.
  @override
  Future<Result<ClaudeCliOutput, AssistantFailure>> run(
    String executable,
    List<String> arguments,
  ) async => Err(ClaudeCliFailures.missing(executable));
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
    expect(models.data, ClaudeCliCatalog.bundledModels);

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

  test('the images of the person and of a tool travel as image blocks on '
      'stdin, labelled in the transcript', () async {
    final launcher = _RecordedLauncher([
      {
        'type': 'result',
        'subtype': 'success',
        'is_error': false,
        'stop_reason': 'end_turn',
        'result': 'Rojo.',
      },
    ]);
    final transport = ClaudeCliTransport(launcher: launcher);
    addTearDown(transport.dispose);
    await transport.initialize(
      tools: const [_echo],
      prompts: const [],
      models: const [],
    );
    final photo = AsystantAttachment.fromBytes(
      bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]),
      filename: 'leaf.jpg',
    );
    final frame = AsystantAttachment.fromBytes(
      bytes: Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]),
      filename: 'frame.png',
    );

    await transport
        .infer(
          messages: [
            AssistantMessage(
              role: MessageRole.user,
              content: 'Look at it',
              attachments: [photo],
            ),
            AssistantMessage(
              role: MessageRole.assistant,
              content: '',
              calls: [
                ToolCall(
                  id: 'call_1',
                  name: 'echo',
                  arguments: ToolArguments.fromJson(const {'text': 'x'}),
                ),
              ],
            ),
            AssistantMessage(
              role: MessageRole.tool,
              content: 'Rendered',
              callId: 'call_1',
              attachments: [frame],
            ),
          ],
          model: 'sonnet',
          requestId: 't1-1',
        )
        .drain<void>();

    final invocation = launcher.invocations.single;
    expect(
      invocation.arguments,
      containsAllInOrder(['--input-format', 'stream-json']),
    );
    // One NDJSON user message, as `--input-format stream-json` expects.
    final line = jsonDecode(invocation.prompt) as Map<String, Object?>;
    expect(line['type'], 'user');
    final content =
        (line['message'] as Map<String, Object?>)['content'] as List<Object?>;
    final transcript =
        (content.first as Map<String, Object?>)['text'] as String;
    expect(transcript, contains(r'"image":"Image 1"'));
    expect(transcript, contains(r'"call_id":"call_1"'));
    expect(transcript, contains(r'"image":"Image 2"'));
    expect(content.skip(1), [
      {'type': 'text', 'text': 'Image 1: "leaf.jpg"'},
      {
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': 'image/jpeg',
          'data': base64Encode(photo.bytes),
        },
      },
      {'type': 'text', 'text': 'Image 2: "frame.png"'},
      {
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': 'image/png',
          'data': base64Encode(frame.bytes),
        },
      },
    ]);
    expect(transport.supportsImageInput('sonnet'), isTrue);
  });

  test(
    'a "too many tokens" error is classified as contextFull, the same as '
    "OpenRouter's own context-length detection",
    () async {
      final launcher = _RecordedLauncher([
        {
          'type': 'result',
          'subtype': 'error_during_execution',
          'is_error': true,
          'result': 'Error: too many tokens in this request',
        },
      ]);
      final transport = ClaudeCliTransport(launcher: launcher);
      addTearDown(transport.dispose);
      await transport.initialize(tools: const [], prompts: const [], models: const []);

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
      expect(failure.code, FailureCode.contextFull);
    },
  );

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
