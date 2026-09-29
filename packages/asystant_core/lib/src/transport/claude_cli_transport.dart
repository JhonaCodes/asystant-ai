import 'dart:async';

import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/model/assistant_failure.dart';
import 'package:asystant_core/src/model/assistant_message.dart';
import 'package:asystant_core/src/model/asystant_prompt_policy.dart';
import 'package:asystant_core/src/model/system_prompt.dart';
import 'package:asystant_core/src/tool/tool_definition.dart';
import 'package:asystant_core/src/transport/assistant_transport.dart';
import 'package:asystant_core/src/transport/claude_cli_launcher.dart';
import 'package:asystant_core/src/transport/claude_cli_launcher_platform.dart';
import 'package:asystant_core/src/transport/claude_cli_protocol.dart';
import 'package:asystant_core/src/transport/claude_cli_stream.dart';
import 'package:asystant_core/src/transport/inference_event.dart';

/// Reasoning effort accepted by `claude --effort`.
enum ClaudeCliEffort { low, medium, high, xhigh, max }

/// Talks to Claude through the Claude Code CLI installed on the machine,
/// with the signed-in user's own subscription and no API key.
///
/// Desktop only: it starts a local process. On the web, and on iOS and
/// Android, every inference fails with [FailureCode.unavailable].
///
/// Each inference is one `claude -p` run with no state of its own: the
/// system prompt (host prompts, per-request context and the tool catalog)
/// goes in a private temporary file, and the whole conversation, tool calls
/// and results included, goes on stdin. See [ClaudeCliProtocol]. The CLI's
/// own tools (Bash, Edit, Read, web access…), MCP servers and the user's
/// Claude Code customizations (CLAUDE.md, memory, hooks, skills) are all
/// disabled, so the model can only propose the host's tools, which the SDK
/// validates and runs like any other transport's calls.
class ClaudeCliTransport extends AssistantTransport {
  ClaudeCliTransport({
    this.executable = 'claude',
    String identity = 'local',
    this.effort,
    this.idleTimeout = const Duration(minutes: 2),
    ClaudeCliLauncher? launcher,
  }) : _identity = identity,
       _launcher = launcher ?? const ProcessClaudeCliLauncher();

  /// Offered when the host passes no models: the CLI's aliases for the
  /// latest model of each family. Any alias or full model name the CLI
  /// accepts (for example `claude-sonnet-4-5` or `opus[1m]`) can be passed
  /// to [initialize] instead; which ones work depends on the subscription.
  static const defaultModels = ['sonnet', 'opus', 'haiku'];

  /// The command to run, looked up on `PATH` and the usual install
  /// locations, or an absolute path.
  final String executable;

  /// Passed as `--effort`; the CLI's default when null.
  final ClaudeCliEffort? effort;

  /// Longest silence from the CLI before the run is abandoned.
  final Duration idleTimeout;

  final String _identity;

  final ClaudeCliLauncher _launcher;

  List<AsystantSystemPrompt> _prompts = const [];

  List<ToolDefinition> _tools = const [];

  ClaudeCliProcess? _active;

  var _epoch = 0;

  var _disposed = false;

  /// A local app has no login: the user's CLI session is the credential.
  @override
  bool get isAuthenticated => true;

  @override
  String? get identity => _identity;

  @override
  Stream<void> get sessionChanges => const Stream.empty();

  @override
  Future<Result<List<String>, AssistantFailure>> initialize({
    required List<ToolDefinition> tools,
    required List<AsystantSystemPrompt> prompts,
    required List<String> models,
  }) async {
    final policy = const AsystantPromptPolicy().compose(prompts);
    final composed = policy.when(ok: (value) => value, err: (_) => null);
    if (composed == null) {
      return Err(policy.errorOrNull ?? const AssistantFailure(.protocol));
    }
    final permitted = [
      for (final model in models.isEmpty ? defaultModels : models)
        if (_isModelName(model)) model,
    ];
    if (permitted.isEmpty) {
      return Err(const AssistantFailure(.unavailable));
    }
    _prompts = composed;
    _tools = List.unmodifiable(tools);
    return Ok(List.unmodifiable(permitted));
  }

  /// A model reaches the command line, so it must not look like a flag.
  static bool _isModelName(String model) =>
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:\[\]-]{0,99}$').hasMatch(model);

  @override
  Stream<InferenceEvent> infer({
    required List<AssistantMessage> messages,
    required String model,
    required String requestId,
    List<AsystantSystemPrompt> context = const [],
  }) async* {
    final epoch = ++_epoch;
    _active?.kill();
    _active = null;
    if (!_isModelName(model)) {
      yield const InferenceFailed(
        AssistantFailure(.protocol, detail: 'Invalid model name'),
      );
      return;
    }
    final started = await _launcher.start(
      ClaudeCliInvocation(
        executable: executable,
        arguments: _arguments(model),
        systemPrompt: ClaudeCliProtocol.systemPrompt(
          prompts: [..._prompts, ...context],
          tools: _tools,
        ),
        prompt: ClaudeCliProtocol.transcript(messages),
      ),
    );
    final process = started.when(ok: (value) => value, err: (_) => null);
    if (process == null) {
      yield InferenceFailed(
        started.errorOrNull ?? const AssistantFailure(.unavailable),
      );
      return;
    }
    if (epoch != _epoch || _disposed) {
      process.kill();
      return;
    }
    _active = process;
    try {
      await for (final event in ClaudeCliStream(
        idleTimeout: idleTimeout,
      ).decode(process, requestId: requestId)) {
        if (epoch != _epoch || _disposed) {
          return;
        }
        yield event;
      }
    } finally {
      if (epoch == _epoch) {
        _active?.kill();
        _active = null;
      }
    }
  }

  /// No prompt text here: see [ClaudeCliInvocation].
  List<String> _arguments(String model) => [
    '-p',
    '--output-format',
    'stream-json',
    '--verbose',
    '--include-partial-messages',
    // The SDK sends the whole conversation every time; nothing to resume.
    '--no-session-persistence',
    // No CLAUDE.md, memory, hooks, skills, plugins or MCP of the user.
    '--safe-mode',
    // Built-in tools off: the model only proposes the host's tools.
    '--tools',
    '',
    '--strict-mcp-config',
    '--model',
    model,
    if (effort case final ClaudeCliEffort level) ...['--effort', level.name],
  ];

  /// Kills the running process. Tool calls it already proposed are not
  /// reported, and nothing it did can be undone (it can do nothing but
  /// write text).
  @override
  void cancel() {
    _epoch++;
    _active?.kill();
    _active = null;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    cancel();
  }
}
