import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/model/assistant_failure.dart';
import 'package:asystant_core/src/transport/claude_cli_launcher.dart';

/// The web build of [ProcessClaudeCliLauncher]: browsers cannot start
/// processes, so every run fails with a clear [AssistantFailure].
///
/// It keeps the same constructor as the desktop launcher, so code that
/// creates one compiles on every platform.
class ProcessClaudeCliLauncher implements ClaudeCliLauncher {
  const ProcessClaudeCliLauncher({this.searchDirectories});

  final List<String>? searchDirectories;

  @override
  Future<Result<ClaudeCliProcess, AssistantFailure>> start(
    ClaudeCliInvocation invocation,
  ) async => Err(ClaudeCliFailures.unsupported);
}
