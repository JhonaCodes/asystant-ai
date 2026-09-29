# Integration guide

## Assistant ownership

Extend `AsystantAI` in the host application. Override `tools` and optionally `systemPrompts` and `contextPrompts()`; pass any display name, and an optional `description`, to the constructor. Own one instance per independent conversation. Closing the chat UI does not destroy it; call `dispose()` when its host owner is destroyed.

Configure the instance once with `init`, passing an `AsystantProvider` (see [Providers](#providers)). `init` only stores the configuration, so it can run before login completes; the chat connects later (see [Deferred startup](#deferred-startup)). Calling `init` a second time throws a `StateError`: create a new assistant instance to replace its provider or configuration.

```dart
assistant.init(
  provider: OpenRouterProvider(
    credentials: fetchAiCredential,
    identity: () => session.userId,
    sessionChanges: session.changes,
    appName: 'Workspace',
  ),
  models: const [
    AsystantModelOption(id: 'openai/gpt-oss-120b', label: 'Precise'),
    AsystantModelOption(id: 'openai/gpt-oss-20b', label: 'Fast'),
  ],
  builtInTools: const [
    PresentationTool(kind: AssistantCardKind.summary),
    PresentationTool(kind: AssistantCardKind.selection),
  ],
);
```

`assistant`, `session` and `fetchAiCredential` are host-owned; see [Credentials and sign-in](#credentials-and-sign-in). `models` are the choices shown next to the send button, each with the provider's model id, a label and an optional icon and description; the first one the transport permits is the default. An empty list lets the provider decide: `OpenRouterProvider` offers the models the credential allows, and `ClaudeCodeProvider` the models the installed CLI declares. Optional built-in tools are enabled only when included; remove one from the list to disable it for a new instance. Duplicate tool names are rejected.

`init` also accepts `additionalSystemPrompts`, a `conversationStore` (an `AsystantConversationStore`; the default `InMemoryConversationStore` forgets conversations when the app closes), an `attachments` policy (`AsystantAttachmentPolicy`, every file type by default) and `turnLimits` (`AsystantTurnLimits`, see [Turn limits](#turn-limits)).

## Providers

A provider says where the answers come from. Everything else in the assistant (tools, system prompts, per-request context, attachments, the model picker, permissions and cards) is the same for every provider: it only talks to the `AssistantTransport` the provider creates.

| Provider | When to use it | What it needs | Platforms |
| --- | --- | --- | --- |
| `OpenRouterProvider` | A published app whose users sign in; usage billed per user with budgets | A `credentials` function returning a short-lived, budget-limited key from your backend (asystant-api) | Android, iOS, web, macOS, Linux, Windows |
| `ClaudeCodeProvider` | A local desktop app for someone who has Claude Code, such as a personal tool | The `claude` CLI installed and signed in with the person's subscription; no key, no backend | macOS, Linux, Windows |

```dart
// A published app: the key comes from your backend.
assistant.init(
  provider: OpenRouterProvider(credentials: fetchAiCredential, appName: 'Workspace'),
);

// A local desktop app: Claude Code is already signed in.
assistant.init(
  provider: const ClaudeCodeProvider(defaultModel: 'sonnet'),
  models: const [
    AsystantModelOption(id: 'sonnet', label: 'Sonnet'),
    AsystantModelOption(id: 'opus', label: 'Opus'),
  ],
);
```

Every provider answers two questions without running an inference, for a settings screen:

- `provider.verify()` returns an `AsystantProviderStatus`: the provider's name, `signedIn` (null when it cannot tell), the version of a local program and a non-secret account description; `isReady` summarizes it. It is an `Err` with a typed `FailureCode` when the provider cannot be reached at all.
- `provider.modelCatalog()` returns an `AsystantModelCatalog`: model ids, effort levels, `isOpenList` (other ids are accepted too) and `source` (`live`, or `bundled` with the SDK).

`AsystantProvider` is sealed, so a host can `switch` over the variants it knows, for example to show provider-specific settings. `init(transport: ...)` remains for an `AssistantTransport` of your own, such as a test double or a proxy; pass exactly one of `provider` and `transport`. The examples use providers.

### How each transport works

Each `infer` streams `TextDelta`s, an optional `UsageReported` and one `InferenceCompleted` whose `message.calls` holds the proposed tool calls, or an `InferenceFailed`. `initialize` registers the tool schemas and prompts and returns the permitted models. A transport never executes a tool.

- `OpenRouterProvider` creates an `OpenRouterTransport`, which calls OpenRouter's Chat Completions API directly from the app, streaming over SSE, with a short-lived, budget-limited key that your backend obtains from asystant-api.
- `ClaudeCodeProvider` creates a `ClaudeCliTransport`, which runs the Claude Code CLI installed on the user's machine, for local apps without a login or API key. It is always authenticated with a fixed `identity`.

`OpenRouterProvider` sends `appName` as `X-Title` and `appUrl` as `HTTP-Referer`, so usage is attributed to the app in OpenRouter. `baseUri` overrides the API root for an OpenRouter-compatible proxy. `maxOutputTokens` and `temperature` are passed through when set. `pdfEngine` chooses how attached PDFs are read (`pdf-text` by default, `mistral-ocr` or `native`). On initialization it reads each permitted model's context window, which feeds the chat's context meter, and the input types it accepts. HTTP failures map to typed `FailureCode`s: 401/403 to `authentication`, 402 to `budget`, 429 to `rateLimited`, a context overflow to `contextFull`, and 5xx to `unavailable`. `verify()` asks OpenRouter about the key (`GET /api/v1/key`).

`ClaudeCodeProvider` makes one stateless `claude -p` run per inference: the whole conversation, tool calls, results and images included, goes on stdin as one stream-json message, and the system prompt, with the per-request context and the tool catalog, goes through a private temporary file. No prompt text is placed on the command line. The CLI keeps no session (`--no-session-persistence`), because the SDK owns and may rewrite the history. Tools are declared in the system prompt, and the model writes each call as a `<tool_call>` JSON block that the transport turns into a `ToolCall`, so the SDK cannot tell it from a native tool call. The CLI's own tools, MCP servers and the user's Claude Code customizations are disabled. `verify()` runs `claude --version` and `claude auth status --json`; `modelCatalog()` reads `claude --help`. A missing binary fails with `FailureCode.unavailable` and a `detail` that says what to install; on the web, iOS and Android every call fails the same way. See the [asystant_core guide](../packages/asystant_core/README.md#claude-code-desktop) for models, isolation, attachments and cancellation.

### Images

Images reach the model by the same path whether the person attached them or a tool returned them (`ToolOutcome.images`): they are the `attachments` of an `AssistantMessage`, and each transport translates them. `transport.supportsImageInput(model)` says whether a model sees them; when it does not, each image is sent as the text of its `AsystantAttachment.imageUnavailableNote`, `[Image not available for this provider: "frame.png" (image/png, 1234 bytes, id …)]`, so the model knows an image was there and can pass its id to a tool.

- `OpenRouterProvider`: supported when the model's `input_modalities` include `image`. The person's images are `image_url` parts of their message. OpenRouter's API only accepts a string as the content of a `tool` message, and content parts such as `image_url` only in `user`, `assistant` and `system` messages ([API reference](https://openrouter.ai/docs/api-reference/overview)), so a tool's images cannot go inside its result: the result says they follow, and one `user` message placed after the last consecutive tool result carries them, each labelled with its `call_id`. It goes after the whole run of results because OpenAI-compatible APIs reject anything between the results of one response.
- `ClaudeCodeProvider`: supported for every model. stdin is one `--input-format stream-json` user message: the transcript as text, then one base64 `image` block per image, labelled as the transcript names it. PNG, JPEG, GIF and WebP up to 5 MB are sent; other images as their note.

## Adding a provider

A provider is self-contained: its folder holds everything it needs, and adding one changes no other provider, no common logic and no host code. In `packages/asystant_core/lib/src/providers/`:

1. **Create its folder**, `providers/<name>/`, with its transport, a class that `extends AssistantTransport` (`initialize`, `infer`, `cancel`, `dispose`, `isAuthenticated`, `identity`, `sessionChanges`), and whatever it needs: codec, stream decoder, launcher, credentials. Override `verify()` and `modelCatalog()` so settings screens can test it and list its models; override `contextLengthOf` and `defaultModel` when the provider knows them. Compose the prompts with `AsystantPromptPolicy().compose(prompts)` in `initialize`, and send `[...prompts, ...context]` on every `infer`, so the security baseline and the per-request context reach the model.
2. **Declare its variant** in `providers/<name>/<name>_provider.dart`, starting with `part of '../asystant_provider.dart';`: a `final class <Name>Provider extends AsystantProvider` with its settings, `name` and `createTransport()`. Dart requires the variants of a sealed class to be in its library, hence the `part`; a part cannot import, so its types come from the import added in step 4.
3. **Write its export file**, `providers/<name>/<name>.dart`, exporting the provider's public types (its transport and anything a host configures).
4. **Register it** with two lines in `providers/asystant_provider.dart`, `import 'package:asystant_core/src/providers/<name>/<name>.dart';` and `part '<name>/<name>_provider.dart';`, and one in `lib/asystant_core.dart`, `export 'package:asystant_core/src/providers/<name>/<name>.dart';`. `asystant_ai` re-exports `asystant_core`, so apps see the new provider after upgrading, with no other change.

**Images.** Messages carry images as `attachments` (see [Images](#images)): the person's on `user` messages, a tool's (`ToolOutcome.images`) on `tool` results. A transport whose provider accepts images sends them in that provider's format and overrides `supportsImageInput(model)` to return true for the models that see them. One that does not keeps the default, false, and sends each image as the text of `AsystantAttachment.imageUnavailableNote` instead, never silently dropping it. Nothing outside the provider's folder changes either way.

A variant without `createTransport()` does not compile, and nothing else dispatches on the provider type, so there is no switch to extend. Hosts that `switch` over `AsystantProvider` get a compile error listing the new variant, which is the intended signal.

## Credentials and sign-in

`OpenRouterProvider` takes an `OpenRouterCredentialSource`: a function returning `Future<Result<OpenRouterCredential, AssistantFailure>>`. In production it asks your own backend, which authenticates the signed-in user and calls asystant-api's `POST /v1/managed/credentials` with the company API key. The backend returns that response body to the app, and `OpenRouterCredential.fromManagedJson` reads it:

```dart
Future<Result<OpenRouterCredential, AssistantFailure>> fetchAiCredential() async {
  final body = await backend.aiCredential(); // Your authenticated endpoint.
  if (body == null) {
    return Err(const AssistantFailure(FailureCode.authentication));
  }
  return Ok(OpenRouterCredential.fromManagedJson(body));
}
```

`backend` is a host-owned client. `fromManagedJson` reads `api_key`, `allowed_models`, `expires_at` and `refresh_after`. You can also build an `OpenRouterCredential(apiKey: ..., allowedModels: ..., expiresAt: ..., refreshAfter: ...)` directly, for example from a short-lived development key passed with `--dart-define`; never compile a key into a release build.

- The transport calls the source on initialization and caches the credential until `refreshAfter` (or `expiresAt` when there is none), then asks again before the next request. A 401 or 403 from OpenRouter drops the cached key, so the next request fetches a new one.
- The key is placed only in the `Authorization` header while sending a request. `OpenRouterCredential.toString()` prints `[REDACTED]`.
- `allowedModels` limits the models: an empty `models` list in `init` offers exactly these; otherwise the host's list is kept in its order, restricted to them. A credential without restrictions accepts the host's list as is. If nothing remains, including an empty list with an unrestricted credential, initialization fails with `FailureCode.unavailable`.
- A failed source fails initialization or the inference with the returned `AssistantFailure`, shown inside the chat.

The company API key issued by asystant-api stays in your backend. It is never sent to the app.

`identity` returns a stable identifier of the current login, or null when signed out (`isAuthenticated` is then false); it defaults to a fixed `'local'`. `sessionChanges` emits whenever the login changes. When the identity differs from the one the conversation started with, the chat cancels the running request, invalidates pending approvals, clears the previous identity's stored conversations and returns to its idle state, where the Connect assistant action runs `ensureInitialized()` again. The transport keeps its cached key until it must be refreshed, so when a different user signs in, dispose the assistant and create a new one, which also creates a new transport.

There is no client-side revocation call. `dispose()` forgets the cached key locally only. Keys are revoked by asystant-api: when a budget is lowered, when the company is suspended, and when the key expires at the end of the UTC day.

## Local tools

`AsystantTool` exposes `definition`, `preview`, `execute`, `requiresConfirmation`, `requiresSelection` and `isAvailable`. `TypedAsystantTool<T>` adds a single domain decoder and typed preview/execution methods. Schema validation rejects unknown fields and wrong scalar types before execution.

A `ToolField` is a scalar (`string`, `integer`, `number`, `boolean`), a list of scalars (`strings`, `numbers`) or a list of objects (`objects`, whose entries have the `fields` you declare). `options` limits a string, or each entry of `strings`, to those values; they travel as the schema's `enum`. A `null` for an optional field counts as absent. When a call is rejected, or a tool returns an `Err`, the failure's `detail` reaches the model with the tool result ("`scene_id` is missing", "`section` does not accept `x`. Valid values: …"), so write a `detail` the model can act on.

`isAvailable` is read before every model call: the model is only offered the tools available at that moment, and a call to one that stopped being available is rejected. Use it to scope tools to what the app shows, such as the current screen.

`ToolOutcome` carries `modelContent`, the text the model reads, and optionally:

- `summary`: what was done, in one line for the person; it replaces the step's title once the tool completes.
- `data`: a structured result for the host, such as the ids a tool created. It stays on the step (`AssistantStep.data`) and is never sent to the model.
- `card`: a genUI card shown in the chat.
- `endsTurn`: ends the person's turn after this tool. The model is not called again and the remaining calls of that response are answered without running, so the next word belongs to the person. Use it when a tool opens a question only the person can answer, such as a product approval, and say so in `modelContent`.
- `images`: images the model looks at with the result, such as a frame the app just rendered so the model can review its own work. Each is an `AsystantAttachment` with PNG, JPEG, GIF or WebP bytes and its `mimeType` (`AsystantAttachment.fromBytes(bytes: png, filename: 'frame.png')`); non-image files are ignored. They stay in the conversation as the `attachments` of the tool's result message, like the person's own attachments, and every provider sends them in its own format (see [Images](#images)).

```dart
@override
Future<Result<ToolOutcome, AssistantFailure>> execute(
  ToolArguments arguments,
  ToolContext context,
) async {
  final png = await canvas.renderPng(); // Host-owned renderer.
  return Ok(
    ToolOutcome(
      modelContent: 'Rendered the current frame; the image is attached.',
      images: [AsystantAttachment.fromBytes(bytes: png, filename: 'frame.png')],
    ),
  );
}
```

Each executed call is an `AssistantStep` with the `toolName`, when it `startedAt`, the `detail` of a failure and the tool's `data`. A turn's steps end up in `ChatEntry.activity`, which a conversation store keeps.

### Progress and cancellation of long tools

A tool that takes a while (a render, an export) reports how far it has come with `ToolContext.reportProgress(fraction, label: ...)`: `fraction` from 0 to 1 (clamped; a non-finite value is ignored) and an optional short `label` for the person, such as "Frame 12 of 48". The running step shows it as `AssistantStep.progress` and `AssistantStep.progressLabel`, and `AssistantStep.showsProgress` is true while it runs with a progress. Report as often as the work advances: the chat shows the first report at once and then at most one every 100 ms, always the latest, so the UI is not rebuilt on every report. Progress never reaches the model, and reports after the call ends or is canceled are ignored. The built-in chat draws it as a thin bar under the step.

`conversation.cancel()` (the chat's Stop button) cancels the turn and reaches the tool that is running: from then on `ToolContext.isCanceled` is true and `checkCanceled()` throws. The SDK cannot interrupt your code, so a long tool checks `isCanceled` as it advances (for example on each progress report) and stops its own work there. The running step ends as `StepPhase.canceled`, and whatever the tool returns afterwards is ignored.

```dart
@override
Future<Result<ToolOutcome, AssistantFailure>> execute(
  ToolArguments arguments,
  ToolContext context,
) async {
  final frames = await renderer.render(
    onFrame: (done, total) {
      if (context.isCanceled) {
        renderer.cancel(); // Host-owned: stop the work.
        return;
      }
      context.reportProgress(done / total, label: 'Frame $done of $total');
    },
  );
  return Ok(ToolOutcome(modelContent: 'Rendered ${frames.length} frames.'));
}
```

A preview must be read-only. Mutating actions require confirmation by default. The model cannot approve its own action. Check `ToolContext.isCanceled` or `checkCanceled()` immediately before an asynchronous write, and use its `idempotencyKey` in your own repository. Existing product authorization is still mandatory; a model-requested action is not an authorization grant.

### Turn limits

The SDK bounds each user turn to 8 inference rounds and 16 tool calls per response by default. `init(turnLimits: ...)` changes them, the same way for every provider, because the chat enforces them, not the transport:

```dart
assistant.init(
  provider: provider,
  turnLimits: const AsystantTurnLimits(maxRounds: 20, maxCallsPerResponse: 8),
);
```

Both are positive integers with a ceiling, so a host mistake cannot leave a turn calling the model without end: `maxRounds` from 1 to `AsystantTurnLimits.maxRoundsCeiling` (64), `maxCallsPerResponse` from 1 to `AsystantTurnLimits.maxCallsCeiling` (16). The call ceiling is the built-in transports' own: `OpenRouterProvider` and `ClaudeCodeProvider` refuse a response with more than 16 calls as a protocol failure, so a higher value could not take effect. `init` throws a `RangeError` for a value outside its range, before storing anything.

When a turn reaches a limit:

- **Rounds.** A round that answers without tool calls ends the turn normally. When the last allowed round still proposes calls, they run as usual (permission included) and their results are added to the conversation, but the model is not asked again. The turn ends with a `FailureCode.limit` failure: the turn's steps stay visible in the chat and the failure notice reads "This operation reached its limit. You can start a new request." The model receives nothing more in that turn; on the person's next message it sees the whole history, those tool results included, with no final answer after them.
- **Calls per response.** A response with more calls than `maxCallsPerResponse` is refused as a `FailureCode.protocol` failure: none of its calls run, the response is not added to the conversation, so the model never sees it, and the chat shows the generic failure notice.

The SDK does not automatically retry uncertain writes or reverse effects already committed. Tool result text returns to the model; optional cards remain in chronological order in the chat.

## Local knowledge (RAG)

The app supplies documents about its own domain (guides, FAQs, policies, catalog entries), and the model searches them with a built-in tool before answering. Everything runs inside the app: no service, no embeddings model, no extra dependency, and it works the same with every provider.

`AsystantKnowledge` is a local index of `KnowledgeDocument`s. Each has an `id` chosen by the app, a `title`, the searchable `text`, and optionally a `collection` (the kind of document, used to narrow a search), `tags` and `metadata` (simple string values the app wants back, such as a route; not searched and not sent to the model). `put` adds a document or replaces the one with the same id, `putAll` adds several, `remove` and `clear` delete.

```dart
final knowledge = AsystantKnowledge(
  documents: [
    for (final guide in await repository.careGuides()) // Host-owned data.
      KnowledgeDocument(
        id: 'guide-${guide.id}',
        title: guide.title,
        text: guide.body,
        collection: 'guides',
        tags: guide.tags,
        metadata: {'route': '/guides/${guide.id}'},
      ),
  ],
);

assistant.init(
  provider: provider,
  builtInTools: [KnowledgeSearchTool(knowledge: knowledge)],
);
```

The model calls `search_knowledge` with a `query`, an optional `collection` (the index's collections are offered as its accepted values) and an optional `limit` (5 by default, at most 10), and reads compact JSON with the passage that matched, not the whole document:

```json
{"query":"riego orquídeas","results":[{"id":"guide-12","title":"Cuidado de la orquídea","collection":"guides","score":2.41,"snippet":"…Riega las orquídeas una vez por semana, por la mañana…"}]}
```

The tool only reads, so it runs without asking for permission; the step shows the query. The ids found are kept in the step's `data['ids']` for the host. `KnowledgeSearchTool` takes `name` (for example to register two indexes as two tools), `description`, `defaultLimit` and `maxLimit`. Documents added or removed later are searched from the next call on; the collections offered are read before each model call.

**Ranking.** `AsystantKnowledge` ranks with BM25, the lexical scoring of classic search engines, over the title (weighted double), the tags and the text. Text is normalized for Spanish and English: lower case, accents folded (`orquídea` = `orquidea`, `ñ` = `n`), common words of both languages dropped, and a light stemmer that joins singular and plural, masculine and feminine (`orquídeas` = `orquídea`, `luces` = `luz`, `cities` = `city`). A query word of four letters or more also matches the longer words it starts (`jardín` finds `jardinería`, `water` finds `watering`). `collection` and `tags` filter before ranking; a document must carry every requested tag. Each hit's `snippet` is the passage of about 320 characters (`snippetLength`) that covers the most query words, cut at a sentence or word boundary with `…`. `rank(query)` is the synchronous form of `search(query)`, for the host's own screens.

**Why lexical, not embeddings.** For this first version the index needs no model, no network and no dependency, runs on mobile, web and desktop, and is deterministic: the same documents and query always give the same order, so it can be tested. It finds the words of the question, not their synonyms: a question about "watering" does not find a document that only says "irrigation", and the model is told to try other words when nothing matches. It searches a few thousand documents in a few milliseconds; building the index costs roughly half a second per million words, so on native platforms build a large one away from the UI isolate, for example `await Isolate.run(() => AsystantKnowledge.fromJson(saved))`.

**Persistence.** `knowledge.toJson()` returns the documents, with a format `version`, as JSON-compatible data, and `AsystantKnowledge.fromJson(json)` rebuilds the index from them. The SDK does not decide where it is stored: a file, a local database or your backend.

**A different retriever.** `KnowledgeSearchTool` depends on `KnowledgeRetriever`, not on the lexical index: a class with `search(KnowledgeQuery)`, returning `Future<Result<List<KnowledgeHit>, AssistantFailure>>`, and optionally `collections`. A semantic or hybrid retriever (embeddings, a vector store, a search service) implements it and replaces `AsystantKnowledge` where it is passed, with no other change in the app or the tool. Return an `Err` only when the retriever cannot answer; its `detail` reaches the model.

Search results come from documents, and the baseline safety prompt already tells the model to treat tool output as untrusted data; index only content the person using the app is allowed to read.

## Embedding and customization

`AsystantButton` opens the chat in a bottom sheet (`AsystantPhoneSheet`) on phones and in a side panel (`AsystantPanel`) on tablets and desktops. `AsystantChat` is a bounded section without its own app router or Scaffold; use it in drawers, panels and full screens. Colors follow the host theme. `AsystantTheme` controls dimensions. `AsystantStrings(spanish: false)` selects English; the default locale-aware widget path supports English and Spanish, and subclassing allows custom wording.

GenUI supports summary, entity, selection, permission and result cards. Selections use stable option strings that tools can map to host domain identifiers. Tool steps show preparing, permission, running, completed, declined, canceled and failed states.

## Backend: asystant-api

[asystant-api](https://github.com/JhonaCodes/asystant-api) is a separate, self-hosted Rust service. It does not proxy inference and the SDK never calls it: your backend does. It gives each client company short-lived, budget-limited OpenRouter keys for its users:

1. An operator creates the company in the asystant-api console, with the OpenRouter workspaces and models it may use, and issues it an API key (`ask_live_...`). That key lives in the company backend's secret manager.
2. The company backend sets budgets per tenant (an organization) and per subject (a person inside it), in a `daily` or a lifetime `migration` bucket.
3. After authenticating a user, the backend calls `POST /v1/managed/credentials` with `{"tenant", "subject", "bucket"}`. The response carries `api_key`, `expires_at` (end of the UTC day), `refresh_after` and `allowed_models`. Repeated calls on the same day return the same key.
4. The app calls OpenRouter directly with that key through `OpenRouterProvider`. OpenRouter enforces the key's spending limit.

The authoritative HTTP contract is its [OpenAPI specification](https://github.com/JhonaCodes/asystant-api/blob/main/openapi.yaml); see its [managed keys guide](https://github.com/JhonaCodes/asystant-api/blob/main/docs/managed-keys.md) and [security policy](https://github.com/JhonaCodes/asystant-api/blob/main/SECURITY.md) before exposing a deployment. Any backend that returns the same JSON body can feed `OpenRouterCredential.fromManagedJson`.

## Deferred startup

`init()` only stores configuration. It does not evaluate application tool getters,
request a credential, or contact the provider. `AsystantChat` starts setup after its first
frame, only when mounted; a launcher button alone does not initialize the assistant.
Do not await assistant readiness before `runApp()` or host authentication.
For a custom chat UI, call `ensureInitialized()` when that UI opens. Concurrent calls
share initialization. Draw it from `assistant.conversation`, a
`ReactiveNotifierViewModel<ChatViewModel, ChatState>`: `ChatState` holds the entries,
the steps of the running turn, the streamed text, the pending permission and the
failure, and `ChatViewModel` exposes `send`, `cancel`, `approve` and
`openConversation`. Network failures remain inside the assistant UI and do not
prevent the host app from starting.

Network I/O uses asynchronous Dart APIs. An isolate is unnecessary for this work and
would not support application tools holding UI or service references. Keep tool
registration cheap; move any genuinely CPU-intensive application computation to an
isolate inside that tool. Startup has no dependency on the assistant's network latency;
this is not a claim of literally zero CPU cost.

Migration from 0.1.0: remove `await` before `init()`. Only headless clients and tests
that immediately send messages should explicitly await `ensureInitialized()`.

## Closing the chat while work continues

Own the `AsystantAI` instance in the authenticated application session, outside
the sheet, drawer or route that displays it. Closing `AsystantChat` only removes
the view. Initialization, pending HTTP requests, local asynchronous tools and
responses continue in the same conversation. Reopen with the same instance to
show its current steps, messages, cards and any pending approval. Reopening does
not resend a message or repeat a tool call.

Do not call `assistant.dispose()` from the chat panel's `dispose()` or close
callback. Use `assistant.conversation.notifier.cancel()` for an explicit Stop
action, and dispose the assistant when its owning login session ends. Changing
the authenticated identity invalidates pending operations and clears old results.
A permission requested while the panel is hidden waits for the user to reopen
and approve; hiding the chat never grants permission.

Provider text is accumulated and published to reactive state in 32 ms batches.
The final response does not wait for that timer. Execution is independent of
mounted widgets and animation frames, so a hidden panel does not stall the tool
loop. Network I/O is asynchronous; it does not need an isolate. A custom tool
that performs substantial synchronous CPU work must offload that calculation
using a platform-appropriate worker (for example `compute` on native Flutter),
passing serializable data and keeping UI/service references in the host isolate.
`compute` does not create a separate worker on Flutter web.

This lifetime applies while the application process can run. It does not promise
execution after a mobile OS suspends/terminates the app, a browser tab is closed,
or the process exits. That requires a separate durable background-job design.

## System prompts and safety

Override the getter for application personality, business terminology and tool
usage guidance. Add session-scoped, non-secret context during configuration:

```dart
class WorkspaceAssistant extends AsystantAI {
  WorkspaceAssistant() : super(name: 'Workspace assistant');

  @override
  List<AsystantTool> get tools => [ReadWorkspaceTool()];

  @override
  List<AsystantSystemPrompt> get systemPrompts => const [
    AsystantSystemPrompt(
      id: 'workspace.personality',
      content: 'Be concise and helpful. Explain proposed changes before asking '
          'for approval. Use tools to confirm current workspace settings.',
    ),
  ];
}

assistant.init(
  provider: provider,
  additionalSystemPrompts: const [
    AsystantSystemPrompt(id: 'workspace.context', content: 'Reply in English.'),
  ],
  builtInTools: const [ChartPresentationTool()],
);
```

`AsystantPromptPolicy.security` is always first. Duplicate IDs, empty instructions,
and replacement of the reserved security ID are rejected. Up to 15 application
prompts may supplement the baseline. Every provider's transport composes the same
baseline again in `initialize`, so it also applies when a transport is used without
the Flutter chat.
The baseline treats retrieved content and tool output as untrusted, prohibits
claiming approval or successful writes without evidence, and instructs the model
not to disclose secrets. It is guidance, not a guarantee against prompt injection.
Never put secrets into prompts; authorization, validation and confirmation remain
mandatory application/server responsibilities.

`contextPrompts()` returns what the app knows right now, such as the person's saved
profile. The chat reads it before every model call and sends it after the configured
prompts, for that request only. Up to `AsystantPromptPolicy.maxContext` (8) entries
are accepted, with the same identity rules. Keep it short and write it as data about
the person rather than as instructions.

## Charts in genUI

Application tools can return an `AssistantCard` containing an `AssistantChart`.
The same component works inside summary, entity, permission and result cards.
Bar and line presentations preserve negative values and include labeled values
for screen readers. Each series is limited to 24 finite measurements; the host
supplies its source, period, unit and completeness. Invalid charts are not rendered.

```dart
const card = AssistantCard(
  title: 'Weekly activity',
  body: '146 completed appointments.',
  chart: AssistantChart(
    title: 'Weekly activity',
    unit: 'appointments',
    source: 'Demo data · Sep 21–25, 2026 · Complete sample',
    points: [
      ChartPoint(label: 'Customer service', value: 72),
      ChartPoint(label: 'Collections', value: 46),
      ChartPoint(label: 'Information', value: 28),
    ],
  ),
);
```

For model-arranged charts, explicitly enable `ChartPresentationTool()` or
`ChartPresentationTool(kind: AssistantChartKind.line)`. This optional tool only
presents data; it cannot fetch private information or change application records.
For authoritative reporting, build the card directly in the local data tool.

## Links, selection and copying

Completed messages and card bodies render Markdown, including named links such as
`[Open settings](https://app.example.com/settings)` and bare HTTP(S) URLs. Links
open only after a user taps them. The default opens the external browser; failures
appear inside the assistant in the selected language. Image markup renders its
alternative text without loading remote images or local files.

The conversation is one selectable area, including streamed text, card titles,
chart labels and results. Use mouse selection and Ctrl+C / Cmd+C on desktop, or
long press and Copy on mobile. Selecting text never follows its links, and active
selection pauses automatic scrolling. Streaming uses plain text until completion,
so partial tokens do not repeatedly parse Markdown.

`AsystantChat` and `AsystantButton` both accept a typed `onOpenLink` callback when
the host needs to route a link within its application:

```dart
AsystantChat(
  assistant: assistant,
  onOpenLink: (uri) async {
    if (uri.host == 'app.example.com' && uri.path == '/settings') {
      await Navigator.of(context).pushNamed('/settings');
      return true;
    }
    return false;
  },
);
```

Return `true` when the host handled navigation, or `false` to show link feedback.
HTTP(S) validation applies before custom callbacks too: credentials in URLs and
schemes such as `javascript`, `data` and `file` are rejected. A standalone
`GenUiCard` can be wrapped in Flutter's `SelectionArea` when used outside the chat.

### Host-owned card content

Pass `cardContentBuilder` to `AsystantChat` or `AsystantButton` to add domain UI
beneath a completed local tool card. Return `null` for cards your host does not
recognize. The standard title, body and chart stay visible. Pending permission
cards never invoke this builder, so custom content cannot replace consent.

```dart
AsystantChat(
  assistant: assistant,
  cardContentBuilder: (context, card) => switch (card) {
    PublicQrCard() => PublicQrPreview(card: card),
    _ => null,
  },
)
```

`PublicQrCard` and `PublicQrPreview` in this example are host-defined types.
A local tool may return an `AssistantCard` subclass with a typed public URL or
artifact identifier. Keep builds free of side effects and start downloads only
from explicit button callbacks. Generate QR images locally; do not interpret
model text as arbitrary widgets, file paths or trusted remote images. Override
`toJson`, `copyWith` and the host decoder when extending card data. The SDK's
base `AssistantCard.fromJson` does not restore host subclasses automatically.
