# asystant_core

Typed local tools, protocol models, the `AssistantTransport` contract and the model providers for embedded AI assistants: `OpenRouterProvider` (HTTP/SSE) and `ClaudeCodeProvider` (the local Claude Code CLI). Pure Dart: usable from Flutter mobile, web and desktop applications, or from a Dart service.

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

Use `TypedAsystantTool<T>` to decode tool arguments into a domain type. Definitions reject duplicate names, unknown arguments and invalid scalar types. For writes, check cancellation immediately before committing and pass `context.idempotencyKey` to your own repository. Cancellation does not undo effects already committed. A long tool reports how far it has come with `context.reportProgress(fraction, label: 'Frame 12 of 48')` (0 to 1) and checks `context.isCanceled` as it advances, to stop its own work when the turn is canceled.

A tool can use `context.supportsPrivateInput` and `context.requestPrivateInput(title, fields)` to request local password, code, TOTP or text fields. The returned map is an execution-only value; the UI package implements the card and an app can opt out. Do not put those values into `ToolOutcome`.

## Local knowledge (RAG)

`AsystantKnowledge` is a local index of the app's own documents, ranked with BM25 and normalized for Spanish and English (accents, plurals, common words). `KnowledgeSearchTool` lets the model search it; each hit carries the matching passage, not the whole document. No service, model or dependency is involved, and the result is deterministic.

```dart
final knowledge = AsystantKnowledge(
  documents: const [
    KnowledgeDocument(
      id: 'faq-shipping',
      title: 'Shipping times',
      collection: 'faq',
      text: 'Orders ship within two business days...',
    ),
  ],
);
final hits = knowledge.rank(const KnowledgeQuery(text: 'shipping time', limit: 3));
final saved = knowledge.toJson(); // Store it wherever the app keeps data.
```

Pass `KnowledgeSearchTool(knowledge: knowledge)` as a tool; the model calls it as `search_knowledge`. A semantic retriever can replace the index by implementing `KnowledgeRetriever`. See [Local knowledge (RAG)](https://github.com/JhonaCodes/asystant-ai/blob/main/docs/public-api.md#local-knowledge-rag).

## Providers

A provider says where the answers come from. `AsystantProvider` is a sealed class; each variant creates its `AssistantTransport`, and tools, prompts, per-request context, attachments and the model catalog go through that contract the same way for every provider.

| Provider | When to use it | What it needs | Platforms |
| --- | --- | --- | --- |
| `OpenRouterProvider` | Direct OpenRouter inference | A `credentials` callback returning a local or server-issued key | Mobile, web, desktop |
| `OpenAICompatibleProvider` | HTTPS Chat Completions inference | A credential callback, base URL and model ID | Mobile, web, desktop |
| `ClaudeCodeProvider` | A local desktop app for someone who has Claude Code | The `claude` CLI installed and signed in; no key, no backend | macOS, Linux, Windows |

Every provider also answers, without running an inference:

- `verify()`: an `AsystantProviderStatus` (provider name, `signedIn`, version of a local program, a non-secret account description), or an `Err` when the provider cannot be reached at all. For a "Test connection" button.
- `modelCatalog()`: an `AsystantModelCatalog` with the model ids and effort levels the provider offers, whether other ids are accepted too (`isOpenList`) and whether it was read live or is bundled with the SDK.

With [asystant_ai](https://pub.dev/packages/asystant_ai), pass the provider to `AsystantAI.init(provider: ...)`. Without Flutter, create its transport and drive it yourself; see [Adding a provider](https://github.com/JhonaCodes/asystant-ai/blob/main/docs/public-api.md#adding-a-provider) to write a new one.

## OpenRouter

`OpenRouterProvider` calls OpenRouter's Chat Completions API directly, streaming over SSE. It takes an `OpenRouterCredentialSource`, a function that returns the signed-in user's short-lived, budget-limited key:

```dart
final provider = OpenRouterProvider(
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

final transport = provider.createTransport();
final models = await transport.initialize(
  tools: [const ReadWorkspaceTool().definition],
  prompts: const [],
  models: const [], // The models the credential allows.
);
```

`backend` and `session` belong to your app. The credential callback maps any authenticated server response to `OpenRouterCredential(apiKey:, allowedModels:, expiresAt:, refreshAfter:)`. `fromManagedJson` is an optional adapter for a matching JSON response. Keep permanent provider credentials on the server, and never compile one into a release build. If a provider cannot issue a scoped client key, use a custom `AssistantTransport` that sends inference through your server.

- The credential is cached until `refreshAfter` (or `expiresAt`) and requested again afterwards; a 401 or 403 drops it. The key only ever goes into the `Authorization` header, and `toString()` redacts it.
- `initialize` keeps the host's models in order, restricted to the credential's `allowedModels`; an empty list offers exactly those. It fails with `FailureCode.unavailable` when none remain.
- `identity` defaults to a fixed `'local'`; `sessionChanges` defaults to an empty stream.
- `baseUri` targets an OpenRouter-compatible proxy; `appName` and `appUrl` attribute usage in OpenRouter; `maxOutputTokens`, `temperature` and `pdfEngine` tune each request.
- HTTP statuses become typed failures: `authentication`, `budget`, `rateLimited`, `contextFull`, `unavailable`, `network` or `protocol`.
- `verify()` asks OpenRouter about the key (`GET /api/v1/key`, no inference): `Ok` when it is accepted, `Err(authentication)` when the source gives none or OpenRouter refuses it. `modelCatalog()` lists the credential's `allowedModels`, as an open list when it has none.

Keep one transport per assistant; call `dispose()` when its owner is destroyed. `dispose()` forgets the cached key locally; the issuer controls server-side revocation.

## Claude Code (desktop)

`ClaudeCodeProvider` runs the [Claude Code](https://docs.claude.com/en/docs/claude-code/setup) CLI installed on the user's machine, with their own Claude subscription, through `ClaudeCliTransport`. There is no API key, login flow or backend: the CLI is already signed in, so the assistant is always authenticated, with a fixed `identity` (default `'local'`) and no session changes.

```dart
const provider = ClaudeCodeProvider(
  defaultModel: 'sonnet', // optional; the first model otherwise
  effort: ClaudeCliEffort.medium, // optional `--effort`
);

// With asystant_ai; with no models, the chat offers the ones the CLI declares.
assistant.init(provider: provider);

final status = await provider.verify(); // `claude --version` + `claude auth status`
final catalog = await provider.modelCatalog(); // read from `claude --help`
```

- **Install**: `npm install -g @anthropic-ai/claude-code` (or the native installer), then run `claude` once in a terminal to sign in. `executable` defaults to `claude`, looked up on `PATH` and then in `~/.local/bin`, `~/.claude/local`, `/opt/homebrew/bin` and `/usr/local/bin`, because macOS apps started from Finder get a minimal `PATH`; the CLI's own directory is put first on the `PATH` it runs with, so an npm install finds its `node`. Pass an absolute path to override it. A missing binary fails with `FailureCode.unavailable` and a `detail` that says what to install; a signed-out CLI fails the inference with `FailureCode.authentication`.
- **Test connection**: `verify()` runs `claude --version` and `claude auth status --json`, which use no inference. `Err(unavailable)` when the binary cannot be run; otherwise `Ok` with the version, `signedIn` and the sign-in method and plan (for example `claude.ai · max`), never the email.
- **Models**: `modelCatalog()` reads `claude --help`, which lists the effort levels and gives the model aliases as examples (`fable`, `opus`, `sonnet` in 2.1.280), so the catalog is an open list: any alias or full model name the CLI accepts (for example `claude-sonnet-4-5` or `opus[1m]`) works too, depending on the subscription. When the help changes shape the catalog falls back to `ClaudeCliCatalog.bundled`, marked `bundled`. With no models, `initialize` offers the catalog's models; with a CLI that cannot run, the bundled ones, and the first inference reports what is missing.
- **Platforms**: desktop only (macOS, Linux, Windows). On the web the package still compiles, through a conditional import, and every call fails with `FailureCode.unavailable`; the same happens on iOS and Android. A macOS app must not run in the App Sandbox, where processes cannot be started.

How it works:

- **One stateless run per inference.** Each `infer` is one `claude -p` run with `--no-session-persistence`. The whole conversation, including tool calls and results, is sent every time, just as the SDK passes it. The CLI's `--resume` is deliberately not used: the SDK owns the history and may rewrite it (a canceled turn gets synthetic tool results, conversations are switched or cleared), so a session kept inside the CLI would drift from it. Resending costs input tokens; the CLI's prompt caching absorbs most of the stable prefix.
- **Tools through the prompt.** `claude -p` cannot register external tools without an MCP server, so the system prompt lists the host's tools as JSON schemas and asks the model to write each call as `<tool_call>{"name": …, "arguments": {…}}</tool_call>`. The transport hides those blocks from the streamed text and returns them as `ToolCall`s in `InferenceCompleted.message.calls`, the same shape as OpenRouter's, so the SDK's permission and tool loop is unchanged. Tool results go back in the next run's transcript, matched by `call_id`. A malformed block fails the inference with `FailureCode.protocol`; it is never guessed. Unlike a native tool channel, calls depend on the model following the format.
- **Isolation.** `--tools ""` disables the CLI's own tools (Bash, Edit, Read, web access…), `--strict-mcp-config` disables every MCP server, and `--safe-mode` keeps the user's `CLAUDE.md`, memory, hooks, skills and plugins out of the assistant. Each run works in a private temporary directory, so project files of the app's working directory are not read either.
- **No prompt on the command line.** A command line is readable by any process on the machine. The system prompt (security baseline, application prompts, per-request context and the tool catalog) goes through `--system-prompt-file` in a private (0700) temporary directory, deleted when the CLI process exits (if the app itself is killed mid-run, it stays in the user's private temporary folder); the transcript and its images go on stdin. Failures keep only a category and a short excerpt of the CLI's error, never the prompt.
- **Streaming and cancellation.** Text streams as `TextDelta` (`--include-partial-messages`), followed by `UsageReported` and `InferenceCompleted`. `cancel()` and `dispose()` kill the process (SIGTERM, then SIGKILL after a second). A run silent for longer than `idleTimeout` (two minutes by default) fails with `FailureCode.network`.
- **Attachments and images.** stdin carries one `--input-format stream-json` user message: the transcript as a text block, then one base64 `image` block for every image the person attached or a tool returned (`ToolOutcome.images`), each after a label (`Image 1: "frame.png"`) that the transcript uses in the file's `"image"` field. PNG, JPEG, GIF and WebP up to 5 MB travel this way; any other image is sent as its `imageUnavailableNote`. Text files travel inside the transcript (up to 60,000 characters each); other files, PDFs included, are announced by name and id so a registered tool can process them.

Tests can pass a `ClaudeCliLauncher` (`ClaudeCodeProvider(launcher: ...)`) that replays recorded output, so the binary is not needed.

## Credential service

This package does not include a hosted service, provider credentials or credits. A host server may issue scoped, short-lived client credentials after authenticating its user; the app maps that response to `OpenRouterCredential`. Keep permanent provider keys on the server. If the provider cannot issue a safe client credential, use a custom transport to keep inference behind the host server. See [Credentials and sign-in](https://github.com/JhonaCodes/asystant-ai/blob/main/docs/public-api.md#credentials-and-sign-in).

To reach another provider, add it as described in [Adding a provider](https://github.com/JhonaCodes/asystant-ai/blob/main/docs/public-api.md#adding-a-provider). Application authorization remains the responsibility of your local tool implementations.

## Example and license

See [example/asystant_core_example.dart](example/asystant_core_example.dart) for a runnable local-tool example. Licensed under MIT; see [LICENSE](LICENSE).
