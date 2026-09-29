part of '../asystant_provider.dart';

/// Claude through the Claude Code CLI installed on the user's machine.
///
/// Nothing to configure for authentication: the CLI uses the subscription
/// its user signed in with (`claude` once in a terminal), so there is no
/// key, backend or login flow, and the assistant always has the fixed
/// [identity]. Desktop only (macOS, Linux, Windows); see
/// [ClaudeCliTransport] for how each run is isolated.
///
/// ```dart
/// assistant.init(provider: const ClaudeCodeProvider(defaultModel: 'sonnet'));
/// ```
final class ClaudeCodeProvider extends AsystantProvider {
  const ClaudeCodeProvider({
    this.executable = 'claude',
    this.identity = 'local',
    this.defaultModel,
    this.effort,
    this.idleTimeout = const Duration(minutes: 2),
    this.launcher,
  });

  /// The command, looked up on `PATH` and the usual install locations, or
  /// an absolute path.
  final String executable;

  /// The fixed identity of this local assistant; conversations are stored
  /// under it.
  final String identity;

  /// The model a new conversation starts with, when permitted. With no
  /// `models` in `init`, the chat offers the ones the CLI declares; see
  /// [modelCatalog].
  final String? defaultModel;

  /// Passed as `--effort`; the CLI's default when null.
  final ClaudeCliEffort? effort;

  /// Longest silence from the CLI before a run is abandoned.
  final Duration idleTimeout;

  /// Starts the CLI; the platform's process launcher when null. Tests pass
  /// one that replays recorded output.
  final ClaudeCliLauncher? launcher;

  @override
  String get name => 'Claude Code';

  @override
  AssistantTransport createTransport() => ClaudeCliTransport(
    executable: executable,
    identity: identity,
    defaultModel: defaultModel,
    effort: effort,
    idleTimeout: idleTimeout,
    launcher: launcher,
  );

  ClaudeCodeProvider copyWith({
    String? executable,
    String? identity,
    String? defaultModel,
    ClaudeCliEffort? effort,
    Duration? idleTimeout,
    ClaudeCliLauncher? launcher,
  }) => ClaudeCodeProvider(
    executable: executable ?? this.executable,
    identity: identity ?? this.identity,
    defaultModel: defaultModel ?? this.defaultModel,
    effort: effort ?? this.effort,
    idleTimeout: idleTimeout ?? this.idleTimeout,
    launcher: launcher ?? this.launcher,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaudeCodeProvider &&
          executable == other.executable &&
          identity == other.identity &&
          defaultModel == other.defaultModel &&
          effort == other.effort &&
          idleTimeout == other.idleTimeout &&
          launcher == other.launcher;

  @override
  int get hashCode => Object.hash(
    executable,
    identity,
    defaultModel,
    effort,
    idleTimeout,
    launcher,
  );

  @override
  String toString() => 'ClaudeCodeProvider($executable)';
}
