import 'package:collection/collection.dart';
import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/model/assistant_failure.dart';

/// One run of the Claude Code CLI, as the transport asks for it.
///
/// [arguments] never carry prompt text: a command line is readable by any
/// process on the machine. The launcher delivers [systemPrompt] through a
/// private temporary file (`--system-prompt-file`) and [prompt] on stdin
/// (for an inference, one `--input-format stream-json` NDJSON line).
/// [toString] leaves both out, so an invocation cannot leak them into logs.
class ClaudeCliInvocation {
  const ClaudeCliInvocation({
    required this.executable,
    required this.arguments,
    required this.systemPrompt,
    required this.prompt,
  });

  /// A command name looked up on the `PATH`, or an absolute path.
  final String executable;

  final List<String> arguments;

  final String systemPrompt;

  final String prompt;

  ClaudeCliInvocation copyWith({
    String? executable,
    List<String>? arguments,
    String? systemPrompt,
    String? prompt,
  }) => ClaudeCliInvocation(
    executable: executable ?? this.executable,
    arguments: List.unmodifiable(arguments ?? this.arguments),
    systemPrompt: systemPrompt ?? this.systemPrompt,
    prompt: prompt ?? this.prompt,
  );

  @override
  bool operator ==(Object other) =>
      other is ClaudeCliInvocation &&
      executable == other.executable &&
      const ListEquality<String>().equals(arguments, other.arguments) &&
      systemPrompt == other.systemPrompt &&
      prompt == other.prompt;

  @override
  int get hashCode =>
      Object.hash(executable, Object.hashAll(arguments), systemPrompt, prompt);

  @override
  String toString() =>
      'ClaudeCliInvocation($executable, ${arguments.length} arguments)';
}

/// A running CLI process, with its two outputs kept apart.
///
/// stdout carries the NDJSON events; stderr carries diagnostics and must
/// never be mixed into it.
class ClaudeCliProcess {
  const ClaudeCliProcess({
    required this.stdoutLines,
    required this.stderrLines,
    required this.exitCode,
    required void Function() kill,
  }) : _kill = kill;

  final Stream<String> stdoutLines;

  final Stream<String> stderrLines;

  final Future<int> exitCode;

  final void Function() _kill;

  /// Ends the process; harmless when it already exited.
  void kill() => _kill();
}

/// What a short CLI command, such as `claude --version`, printed.
class ClaudeCliOutput {
  const ClaudeCliOutput({required this.exitCode, required this.stdout});

  final int exitCode;

  /// Everything written to stdout, bounded by the launcher.
  final String stdout;

  ClaudeCliOutput copyWith({int? exitCode, String? stdout}) => ClaudeCliOutput(
    exitCode: exitCode ?? this.exitCode,
    stdout: stdout ?? this.stdout,
  );

  @override
  bool operator ==(Object other) =>
      other is ClaudeCliOutput &&
      exitCode == other.exitCode &&
      stdout == other.stdout;

  @override
  int get hashCode => Object.hash(exitCode, stdout);

  @override
  String toString() => 'ClaudeCliOutput($exitCode, ${stdout.length} chars)';
}

/// Starts the Claude Code CLI.
///
/// The transport depends on this interface, so tests replay recorded output
/// without the binary installed. A missing binary is an `Err`, not an
/// exception.
abstract interface class ClaudeCliLauncher {
  /// One inference run: [ClaudeCliInvocation.prompt] on stdin, the system
  /// prompt through a private file.
  Future<Result<ClaudeCliProcess, AssistantFailure>> start(
    ClaudeCliInvocation invocation,
  );

  /// A short command that sends no prompt and uses no inference, such as
  /// `--version`, `--help` or `auth status --json`, with its output.
  ///
  /// [arguments] must never carry prompt text or a secret.
  Future<Result<ClaudeCliOutput, AssistantFailure>> run(
    String executable,
    List<String> arguments,
  );
}

/// The failures every launcher reports the same way.
abstract final class ClaudeCliFailures {
  /// The binary could not be found or started.
  static AssistantFailure missing(String executable) => AssistantFailure(
    .unavailable,
    detail:
        'Claude Code CLI "$executable" was not found. Install it '
        '(https://docs.claude.com/en/docs/claude-code/setup, for example '
        '`npm install -g @anthropic-ai/claude-code`), run `claude` once in a '
        'terminal to sign in with your subscription, or pass its absolute '
        'path as `executable`.',
  );

  /// The platform cannot start processes, as on the web.
  static const AssistantFailure unsupported = AssistantFailure(
    .unavailable,
    detail:
        'ClaudeCliTransport starts a local process and only works on '
        'desktop platforms (macOS, Linux, Windows), not on the web or mobile.',
  );

  /// A short command did not finish in time.
  static AssistantFailure silent(String command) => AssistantFailure(
    .network,
    detail: 'Claude Code did not answer `$command` in time.',
  );
}
