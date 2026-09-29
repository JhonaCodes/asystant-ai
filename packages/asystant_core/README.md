# asystant_core

Typed local tools, protocol models and the `AssistantTransport` contract for embedded AI assistants, with two transports: `OpenRouterTransport` (HTTP/SSE) and `ClaudeCliTransport` (the local Claude Code CLI). Pure Dart: usable from Flutter mobile, web and desktop applications, or from a Dart service.

## Install

```sh
dart pub add asystant_core
```

For a ready-to-embed Flutter chat, use [asystant_ai](https://pub.dev/packages/asystant_ai).

## Define a local tool

Tools run in your application, using its existing authorization and services. The model receives only their schemas. Mutating tools require confirmation by default.

```dart
import 'package:asystant_core/asystant_core.dart';

class ReadWorkspaceTool extends AsystantTool {
  const ReadWorkspaceTool();

  @override
  ToolDefinition get definition => const ToolDefinition(
    name: 'read_workspace',
    description: 'Read the current workspace name.',
    fields: [],
  );

  @override
  bool get requiresConfirmation => false;

  @override
  Future<Result<AssistantCard, AssistantFailure>> preview(
    ToolArguments arguments,
  ) async => Ok(const AssistantCard(title: 'Current workspace'));

  @override
  Future<Result<ToolOutcome, AssistantFailure>> execute(
    ToolArguments arguments,
    ToolContext context,
  ) async {
    context.checkCanceled();
    return Ok(const ToolOutcome(modelContent: 'Example workspace'));
  }
}
```

Use `TypedAsystantTool<T>` to decode tool arguments into a domain type. Definitions reject duplicate names, unknown arguments and invalid scalar types. For writes, check cancellation immediately before committing and pass `context.idempotencyKey` to your own repository. Cancellation does not undo effects already committed.

## OpenRouter transport

`OpenRouterTransport` calls OpenRouter's Chat Completions API directly, streaming over SSE. It takes an `OpenRouterCredentialSource`, a function that returns the signed-in user's short-lived, budget-limited key:

```dart
final transport = OpenRouterTransport(
  credentials: () async {
    final body = await backend.aiCredential(); // Your authenticated endpoint.
    return body == null
        ? Err(const AssistantFailure(FailureCode.authentication))
        : Ok(OpenRouterCredential.fromManagedJson(body));
  },
  identity: () => session.userId, // null when signed out.
  sessionChanges: session.changes, // Emits when the login changes.
  appName: 'Workspace',
);

final models = await transport.initialize(
  tools: [const ReadWorkspaceTool().definition],
  prompts: const [],
  models: const [], // The models the credential allows.
);
```

`backend` and `session` belong to your app. In production your backend authenticates the user and calls [asystant-api](https://github.com/JhonaCodes/asystant-api)'s `POST /v1/managed/credentials`; `OpenRouterCredential.fromManagedJson` reads its response (`api_key`, `allowed_models`, `expires_at`, `refresh_after`). Keep the asystant-api company key in your backend, and never compile a provider key into a release build.

- The credential is cached until `refreshAfter` (or `expiresAt`) and requested again afterwards; a 401 or 403 drops it. The key only ever goes into the `Authorization` header, and `toString()` redacts it.
- `initialize` keeps the host's models in order, restricted to the credential's `allowedModels`; an empty list offers exactly those. It fails with `FailureCode.unavailable` when none remain.
- `identity` defaults to a fixed `'local'`; `sessionChanges` defaults to an empty stream.
- `baseUri` targets an OpenRouter-compatible proxy; `appName` and `appUrl` attribute usage in OpenRouter; `maxOutputTokens`, `temperature` and `pdfEngine` tune each request.
- HTTP statuses become typed failures: `authentication`, `budget`, `rateLimited`, `contextFull`, `unavailable`, `network` or `protocol`.

Keep one transport per assistant; call `dispose()` when its owner is destroyed. `dispose()` forgets the cached key locally; revocation is done by asystant-api.

## Claude Code CLI transport (desktop)

`ClaudeCliTransport` runs the [Claude Code](https://docs.claude.com/en/docs/claude-code/setup) CLI installed on the user's machine, with their own Claude subscription. There is no API key, login flow or backend: the transport is always authenticated, with a fixed `identity` (default `'local'`) and no session changes.

```dart
final transport = ClaudeCliTransport(
  identity: 'local',
  effort: ClaudeCliEffort.medium, // optional `--effort`
);

// With asystant_ai; an empty list offers ClaudeCliTransport.defaultModels.
assistant.init(
  transport: transport,
  models: const [
    AsystantModelOption(id: 'sonnet', label: 'Sonnet'),
    AsystantModelOption(id: 'opus', label: 'Opus'),
  ],
);
```

- **Install**: `npm install -g @anthropic-ai/claude-code` (or the native installer), then run `claude` once in a terminal to sign in. `executable` defaults to `claude`, looked up on `PATH` and then in `~/.local/bin`, `~/.claude/local`, `/opt/homebrew/bin` and `/usr/local/bin`, because macOS apps started from Finder get a minimal `PATH`. Pass an absolute path to override it. A missing binary fails the inference with `FailureCode.unavailable` and a `detail` that says what to install; a signed-out CLI fails with `FailureCode.authentication`.
- **Models**: with no models, `initialize` offers `ClaudeCliTransport.defaultModels` (`sonnet`, `opus`, `haiku`, the CLI's aliases for the latest model of each family). Any alias or full model name the CLI accepts can be passed instead; availability depends on the subscription.
- **Platforms**: desktop only (macOS, Linux, Windows). On the web the package still compiles, through a conditional import, and every inference fails with `FailureCode.unavailable`; the same happens on iOS and Android. A macOS app must not run in the App Sandbox, where processes cannot be started.

How it works:

- **One stateless run per inference.** Each `infer` is one `claude -p` run with `--no-session-persistence`. The whole conversation, including tool calls and results, is sent every time, just as the SDK passes it. The CLI's `--resume` is deliberately not used: the SDK owns the history and may rewrite it (a canceled turn gets synthetic tool results, conversations are switched or cleared), so a session kept inside the CLI would drift from it. Resending costs input tokens; the CLI's prompt caching absorbs most of the stable prefix.
- **Tools through the prompt.** `claude -p` cannot register external tools without an MCP server, so the system prompt lists the host's tools as JSON schemas and asks the model to write each call as `<tool_call>{"name": …, "arguments": {…}}</tool_call>`. The transport hides those blocks from the streamed text and returns them as `ToolCall`s in `InferenceCompleted.message.calls`, the same shape as `OpenRouterTransport`, so the SDK's permission and tool loop is unchanged. Tool results go back in the next run's transcript, matched by `call_id`. A malformed block fails the inference with `FailureCode.protocol`; it is never guessed. Unlike a native tool channel, calls depend on the model following the format.
- **Isolation.** `--tools ""` disables the CLI's own tools (Bash, Edit, Read, web access…), `--strict-mcp-config` disables every MCP server, and `--safe-mode` keeps the user's `CLAUDE.md`, memory, hooks, skills and plugins out of the assistant. Each run works in a private temporary directory, so project files of the app's working directory are not read either.
- **No prompt on the command line.** A command line is readable by any process on the machine. The system prompt (security baseline, application prompts, per-request context and the tool catalog) goes through `--system-prompt-file` in a private (0700) temporary directory, deleted when the CLI process exits (if the app itself is killed mid-run, it stays in the user's private temporary folder); the transcript goes on stdin. Failures keep only a category and a short excerpt of the CLI's error, never the prompt.
- **Streaming and cancellation.** Text streams as `TextDelta` (`--include-partial-messages`), followed by `UsageReported` and `InferenceCompleted`. `cancel()` and `dispose()` kill the process (SIGTERM, then SIGKILL after a second). A run silent for longer than `idleTimeout` (two minutes by default) fails with `FailureCode.network`.
- **Attachments.** Text files travel inside the transcript (up to 60,000 characters each); other files are announced by name and id so a registered tool can process them. Images and PDFs are not sent to the model.

Tests can inject a `ClaudeCliLauncher` that replays recorded output, so the binary is not needed.

## Credential service

[asystant-api](https://github.com/JhonaCodes/asystant-api) is a separate, self-hosted service that issues OpenRouter keys to client backends, with budgets per tenant and per user and revocation handled server-side. It does not proxy inference and this package never calls it. Read its [HTTP contract](https://github.com/JhonaCodes/asystant-api/blob/main/openapi.yaml), [managed keys guide](https://github.com/JhonaCodes/asystant-api/blob/main/docs/managed-keys.md) and [deployment guide](https://github.com/JhonaCodes/asystant-api/blob/main/docs/deployment.md). This package does not include a hosted service or provider credits.

To reach another provider or your own service, implement `AssistantTransport`. Application authorization remains the responsibility of your local tool implementations.

## Example and license

See [example/asystant_core_example.dart](example/asystant_core_example.dart) for a runnable local-tool example. Licensed under MIT; see [LICENSE](LICENSE).
