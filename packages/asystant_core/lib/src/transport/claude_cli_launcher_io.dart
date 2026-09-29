import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/model/assistant_failure.dart';
import 'package:asystant_core/src/transport/claude_cli_launcher.dart';

/// Starts the CLI with `dart:io` on desktop platforms.
///
/// Each run gets a private temporary directory (created with mode 0700). The
/// system prompt is written there and passed as `--system-prompt-file`; the
/// directory is also the working directory, so no project `CLAUDE.md` or
/// `.claude/` settings of the host's current directory reach the model. It is
/// deleted when the process exits. The prompt goes on stdin.
///
/// A macOS app must not run in the App Sandbox: there `Process.start` always
/// fails. Apps launched from Finder also get a minimal `PATH`, so a bare
/// command name is looked up on `PATH` and then in [searchDirectories].
class ProcessClaudeCliLauncher implements ClaudeCliLauncher {
  const ProcessClaudeCliLauncher({this.searchDirectories});

  /// Where to look after `PATH`; defaults to the usual install locations.
  final List<String>? searchDirectories;

  static List<String> _defaultDirectories(String home) => [
    '$home/.local/bin',
    '$home/.claude/local',
    '/opt/homebrew/bin',
    '/usr/local/bin',
  ];

  @override
  Future<Result<ClaudeCliProcess, AssistantFailure>> start(
    ClaudeCliInvocation invocation,
  ) async {
    if (Platform.isIOS || Platform.isAndroid) {
      return Err(ClaudeCliFailures.unsupported);
    }
    final executable = await _resolve(invocation.executable);
    if (executable == null) {
      return Err(ClaudeCliFailures.missing(invocation.executable));
    }
    final Directory workspace;
    try {
      workspace = await Directory.systemTemp.createTemp('asystant_claude_');
    } on FileSystemException {
      return Err(
        const AssistantFailure(
          .unavailable,
          detail: 'Could not create a private temporary directory.',
        ),
      );
    }
    final Process process;
    try {
      final systemPrompt = File('${workspace.path}/system-prompt.md');
      await systemPrompt.writeAsString(invocation.systemPrompt, flush: true);
      process = await Process.start(executable, [
        ...invocation.arguments,
        '--system-prompt-file',
        systemPrompt.path,
      ], workingDirectory: workspace.path);
    } on ProcessException {
      // Its message repeats the command line; it is deliberately dropped.
      _remove(workspace);
      return Err(ClaudeCliFailures.missing(invocation.executable));
    } on FileSystemException {
      _remove(workspace);
      return Err(
        const AssistantFailure(
          .unavailable,
          detail: 'Could not write the system prompt file.',
        ),
      );
    }
    var exited = false;
    unawaited(
      process.exitCode.whenComplete(() {
        exited = true;
        _remove(workspace);
      }),
    );
    // A process that exits early closes stdin; that error is expected and
    // the missing result is reported from stdout instead.
    process.stdin.write(invocation.prompt);
    process.stdin.close().ignore();
    return Ok(
      ClaudeCliProcess(
        stdoutLines: process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter()),
        stderrLines: process.stderr
            .transform(utf8.decoder)
            .transform(const LineSplitter()),
        exitCode: process.exitCode,
        kill: () => _stop(process, exited: () => exited),
      ),
    );
  }

  /// SIGTERM first. Once nobody reads its stdout the CLI can take seconds
  /// to shut down, so it gets SIGKILL if it is still running after that.
  static void _stop(Process process, {required bool Function() exited}) {
    if (exited() || !process.kill()) {
      return;
    }
    Timer(const Duration(seconds: 1), () {
      if (!exited()) {
        process.kill(ProcessSignal.sigkill);
      }
    });
  }

  static void _remove(Directory directory) =>
      directory.delete(recursive: true).ignore();

  /// An absolute path when [command] can be run, otherwise null.
  Future<String?> _resolve(String command) async {
    if (command.contains('/') || command.contains(r'\')) {
      return await File(command).exists() ? command : null;
    }
    final environment = Platform.environment;
    final separator = Platform.isWindows ? ';' : ':';
    final home = environment['HOME'] ?? environment['USERPROFILE'] ?? '';
    final directories = [
      ...?environment['PATH']?.split(separator),
      ...searchDirectories ?? _defaultDirectories(home),
    ];
    final names = Platform.isWindows ? ['$command.exe', command] : [command];
    for (final directory in directories) {
      if (directory.isEmpty) {
        continue;
      }
      for (final name in names) {
        final candidate = '$directory${Platform.pathSeparator}$name';
        if (await File(candidate).exists()) {
          return candidate;
        }
      }
    }
    return null;
  }
}
