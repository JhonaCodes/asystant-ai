/// [ProcessClaudeCliLauncher] for the current platform: `dart:io` where it
/// exists, a stub that reports the platform as unsupported on the web.
library;

export 'package:asystant_core/src/transport/claude_cli_launcher_web.dart'
    if (dart.library.io) 'package:asystant_core/src/transport/claude_cli_launcher_io.dart';
