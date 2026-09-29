import 'package:asystant_core/asystant_core.dart';
import 'package:test/test.dart';

void main() {
  // That every variant has its transport is checked by the compiler:
  // `createTransport` is abstract in the sealed `AsystantProvider`.
  test('each provider creates its own transport, configured as it says', () {
    final claude = const ClaudeCodeProvider(
      executable: '/opt/claude/bin/claude',
      identity: 'desk',
      defaultModel: 'opus',
      effort: ClaudeCliEffort.high,
      idleTimeout: Duration(seconds: 30),
    ).createTransport();
    final openRouter = OpenRouterProvider(
      credentials: () async => Ok(const OpenRouterCredential(apiKey: 'k')),
      identity: () => 'user-1',
      appName: 'Workspace',
      pdfEngine: 'native',
      maxOutputTokens: 800,
    ).createTransport();
    addTearDown(claude.dispose);
    addTearDown(openRouter.dispose);

    expect(
      claude,
      isA<ClaudeCliTransport>()
          .having((t) => t.executable, 'executable', '/opt/claude/bin/claude')
          .having((t) => t.identity, 'identity', 'desk')
          .having((t) => t.configuredDefaultModel, 'defaultModel', 'opus')
          .having((t) => t.effort, 'effort', ClaudeCliEffort.high)
          .having(
            (t) => t.idleTimeout,
            'idleTimeout',
            const Duration(seconds: 30),
          )
          .having((t) => t.isAuthenticated, 'isAuthenticated', isTrue),
    );
    expect(
      openRouter,
      isA<OpenRouterTransport>()
          .having((t) => t.identity, 'identity', 'user-1')
          .having((t) => t.appName, 'appName', 'Workspace')
          .having((t) => t.pdfEngine, 'pdfEngine', 'native')
          .having((t) => t.maxOutputTokens, 'maxOutputTokens', 800),
    );
  });
}
