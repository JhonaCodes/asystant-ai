import 'dart:convert';

import 'package:asystant_ai/asystant_ai.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_flow_test.dart' show settle;

/// Answers like the Claude Code CLI without starting it: a tool call first,
/// then a reply that uses the tool's result.
class _RecordedLauncher implements ClaudeCliLauncher {
  final List<ClaudeCliInvocation> invocations = [];

  @override
  Future<Result<ClaudeCliProcess, AssistantFailure>> start(
    ClaudeCliInvocation invocation,
  ) async {
    invocations.add(invocation);
    final reply = invocations.length == 1
        ? '<tool_call>{"name": "echo", "arguments": {"text": "hola"}}'
              '</tool_call>'
        : 'The tool said: hola';
    return Ok(
      ClaudeCliProcess(
        stdoutLines: Stream.fromIterable([
          jsonEncode({
            'type': 'assistant',
            'message': {
              'content': [
                {'type': 'text', 'text': reply},
              ],
            },
          }),
          jsonEncode({
            'type': 'result',
            'subtype': 'success',
            'is_error': false,
            'stop_reason': 'end_turn',
          }),
        ]),
        stderrLines: const Stream.empty(),
        exitCode: Future.value(0),
        kill: () {},
      ),
    );
  }

  @override
  Future<Result<ClaudeCliOutput, AssistantFailure>> run(
    String executable,
    List<String> arguments,
  ) async => Err(ClaudeCliFailures.missing(executable));
}

/// Repeats its text; runs without asking.
class _Echo extends AsystantTool {
  @override
  bool get requiresConfirmation => false;

  @override
  ToolDefinition get definition => const ToolDefinition(
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

  @override
  Future<Result<AssistantCard, AssistantFailure>> preview(
    ToolArguments arguments,
  ) async => Ok(const AssistantCard(title: 'Echo'));

  @override
  Future<Result<ToolOutcome, AssistantFailure>> execute(
    ToolArguments arguments,
    ToolContext context,
  ) async =>
      Ok(ToolOutcome(modelContent: 'echo: ${arguments.toJson()['text']}'));
}

class _Assistant extends AsystantAI {
  _Assistant() : super(name: 'Assistant');

  @override
  List<AsystantTool> get tools => [_Echo()];

  @override
  List<AsystantSystemPrompt> get systemPrompts => const [
    AsystantSystemPrompt(id: 'app', content: 'You help with the workspace.'),
  ];

  @override
  Future<List<AsystantSystemPrompt>> contextPrompts() async => const [
    AsystantSystemPrompt(id: 'profile', content: 'Allergy: pollen'),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('with ClaudeCodeProvider the tools, prompts and per-request context '
      'reach the CLI, and a tool call runs like with any provider', () async {
    final launcher = _RecordedLauncher();
    final assistant = _Assistant()
      ..init(
        provider: ClaudeCodeProvider(launcher: launcher),
        models: const [AsystantModelOption(id: 'sonnet', label: 'Sonnet')],
      );
    addTearDown(assistant.dispose);
    await assistant.ensureInitialized();

    await assistant.sendMessage('Repeat hola');
    await settle();

    expect(launcher.invocations, hasLength(2));
    final first = launcher.invocations.first;
    expect(first.arguments, containsAllInOrder(['--model', 'sonnet']));
    expect(first.systemPrompt, contains('"name":"echo"'));
    expect(first.systemPrompt, contains('You help with the workspace.'));
    expect(first.systemPrompt, contains('Allergy: pollen'));
    expect(first.prompt, contains('Repeat hola'));
    // The tool ran in the app and its result went back to the model.
    expect(launcher.invocations.last.prompt, contains('echo: hola'));
    expect(
      assistant.conversation.notifier.state.messages.last.content,
      'The tool said: hola',
    );
  });
}
