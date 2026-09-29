# Integration guide

## Assistant ownership

Extend `AsystantAI` in the host application. Override `tools` and optionally `systemPrompts` and `contextPrompts()`; pass any display name, and an optional `description`, to the constructor. Own one instance per independent conversation. Closing the chat UI does not destroy it; call `dispose()` when its host owner is destroyed.

Configure the instance once with `init`, passing an `AssistantTransport`. `init` only stores the configuration, so it can run before login completes; the chat connects later (see [Deferred startup](#deferred-startup)). Calling `init` a second time throws a `StateError`: create a new assistant instance to replace its transport or configuration.

```dart
assistant.init(
  transport: OpenRouterTransport(
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

`assistant`, `session` and `fetchAiCredential` are host-owned; see [Credentials and sign-in](#credentials-and-sign-in). `models` are the choices shown next to the send button, each with the provider's model id, a label and an optional icon and description; the first one the transport permits is the default. An empty list lets the transport decide: `OpenRouterTransport` offers the models the credential allows, and `ClaudeCliTransport` offers `ClaudeCliTransport.defaultModels`. Optional built-in tools are enabled only when included; remove one from the list to disable it for a new instance. Duplicate tool names are rejected.

`init` also accepts `additionalSystemPrompts`, a `conversationStore` (an `AsystantConversationStore`; the default `InMemoryConversationStore` forgets conversations when the app closes) and an `attachments` policy (`AsystantAttachmentPolicy`, every file type by default).

## Transports

Every transport implements `AssistantTransport`; the chat, permissions and tool loop do not depend on which one is used. `initialize` registers the tool schemas and prompts and returns the permitted models. Each `infer` streams `TextDelta`s, an optional `UsageReported` and one `InferenceCompleted` whose `message.calls` holds the proposed tool calls, or an `InferenceFailed`. A transport never executes a tool. Implement `AssistantTransport` yourself to reach another provider or your own service.

- `OpenRouterTransport` calls OpenRouter's Chat Completions API directly from the app, streaming over SSE, with a short-lived, budget-limited key that your backend obtains from asystant-api.
- `ClaudeCliTransport` (desktop only) runs the Claude Code CLI installed on the user's machine with their own subscription, for local apps without a login or API key. It is always authenticated with a fixed `identity`.

```dart
assistant.init(
  transport: ClaudeCliTransport(identity: 'local'),
  models: const [AsystantModelOption(id: 'sonnet', label: 'Sonnet')],
);
```

`OpenRouterTransport` sends `appName` as `X-Title` and `appUrl` as `HTTP-Referer`, so usage is attributed to the app in OpenRouter. `baseUri` overrides the API root for an OpenRouter-compatible proxy. `maxOutputTokens` and `temperature` are passed through when set. `pdfEngine` chooses how attached PDFs are read (`pdf-text` by default, `mistral-ocr` or `native`). On initialization it reads each permitted model's context window, which feeds the chat's context meter, and the input types it accepts. HTTP failures map to typed `FailureCode`s: 401/403 to `authentication`, 402 to `budget`, 429 to `rateLimited`, a context overflow to `contextFull`, and 5xx to `unavailable`.

`ClaudeCliTransport` makes one stateless `claude -p` run per inference: the whole conversation, tool calls and results included, goes on stdin, and the system prompt, with the tool catalog, goes through a private temporary file. No prompt text is placed on the command line. The CLI keeps no session (`--no-session-persistence`), because the SDK owns and may rewrite the history. Tools are declared in the system prompt, and the model writes each call as a `<tool_call>` JSON block that the transport turns into a `ToolCall`, so the SDK cannot tell it from a native tool call. The CLI's own tools, MCP servers and the user's Claude Code customizations are disabled. A missing binary fails with `FailureCode.unavailable` and a `detail` that says what to install; on the web, iOS and Android every inference fails the same way. See the [asystant_core guide](../packages/asystant_core/README.md#claude-code-cli-transport-desktop) for models, isolation, attachments and cancellation.

## Credentials and sign-in

`OpenRouterTransport` takes an `OpenRouterCredentialSource`: a function returning `Future<Result<OpenRouterCredential, AssistantFailure>>`. In production it asks your own backend, which authenticates the signed-in user and calls asystant-api's `POST /v1/managed/credentials` with the company API key. The backend returns that response body to the app, and `OpenRouterCredential.fromManagedJson` reads it:

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

A preview must be read-only. Mutating actions require confirmation by default. The model cannot approve its own action. Check `ToolContext.isCanceled` or `checkCanceled()` immediately before an asynchronous write, and use its `idempotencyKey` in your own repository. Existing product authorization is still mandatory; a model-requested action is not an authorization grant.

The SDK bounds each user turn to eight inference rounds and sixteen calls per response. It does not automatically retry uncertain writes or reverse effects already committed. Tool result text returns to the model; optional cards remain in chronological order in the chat.

## Embedding and customization

`AsystantButton` opens the chat in a bottom sheet (`AsystantPhoneSheet`) on phones and in a side panel (`AsystantPanel`) on tablets and desktops. `AsystantChat` is a bounded section without its own app router or Scaffold; use it in drawers, panels and full screens. Colors follow the host theme. `AsystantTheme` controls dimensions. `AsystantStrings(spanish: false)` selects English; the default locale-aware widget path supports English and Spanish, and subclassing allows custom wording.

GenUI supports summary, entity, selection, permission and result cards. Selections use stable option strings that tools can map to host domain identifiers. Tool steps show preparing, permission, running, completed, declined, canceled and failed states.

## Backend: asystant-api

[asystant-api](https://github.com/JhonaCodes/asystant-api) is a separate, self-hosted Rust service. It does not proxy inference and the SDK never calls it: your backend does. It gives each client company short-lived, budget-limited OpenRouter keys for its users:

1. An operator creates the company in the asystant-api console, with the OpenRouter workspaces and models it may use, and issues it an API key (`ask_live_...`). That key lives in the company backend's secret manager.
2. The company backend sets budgets per tenant (an organization) and per subject (a person inside it), in a `daily` or a lifetime `migration` bucket.
3. After authenticating a user, the backend calls `POST /v1/managed/credentials` with `{"tenant", "subject", "bucket"}`. The response carries `api_key`, `expires_at` (end of the UTC day), `refresh_after` and `allowed_models`. Repeated calls on the same day return the same key.
4. The app calls OpenRouter directly with that key through `OpenRouterTransport`. OpenRouter enforces the key's spending limit.

The authoritative HTTP contract is its [OpenAPI specification](https://github.com/JhonaCodes/asystant-api/blob/main/openapi.yaml); see its [managed keys guide](https://github.com/JhonaCodes/asystant-api/blob/main/docs/managed-keys.md) and [security policy](https://github.com/JhonaCodes/asystant-api/blob/main/SECURITY.md) before exposing a deployment. Any backend that returns the same JSON body can feed `OpenRouterCredential.fromManagedJson`.

## Deferred startup

`init()` only stores configuration. It does not evaluate application tool getters,
request a credential, or contact the provider. `AsystantChat` starts setup after its first
frame, only when mounted; a launcher button alone does not initialize the assistant.
Do not await assistant readiness before `runApp()` or host authentication.
For a custom chat UI, call `ensureInitialized()` when that UI opens. Concurrent calls
share initialization. Network failures remain inside the assistant UI and do not
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
  transport: transport,
  additionalSystemPrompts: const [
    AsystantSystemPrompt(id: 'workspace.context', content: 'Reply in English.'),
  ],
  builtInTools: const [ChartPresentationTool()],
);
```

`AsystantPromptPolicy.security` is always first. Duplicate IDs, empty instructions,
and replacement of the reserved security ID are rejected. Up to 15 application
prompts may supplement the baseline. `OpenRouterTransport` and `ClaudeCliTransport`
compose the same baseline again in `initialize`, so it also applies when a transport
is used without the Flutter chat.
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
