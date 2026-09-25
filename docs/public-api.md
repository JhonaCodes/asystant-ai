# Integration guide

## Assistant ownership

Extend `AsystantAI` in the host application. Override `tools` and optionally `systemPrompts`; pass any display name to the constructor. Own one instance per independent conversation. Closing the chat UI does not destroy it; call `dispose()` when its host owner is destroyed.

Initialize after the application services and login are ready. If initialization depends on mounted widgets, invoke it after the first frame; otherwise initialize before mounting the chat. Never rely on a frame callback as proof of authentication.

```dart
assistant.init(
  transport: GatewayTransport(baseUri: gatewayUri, sessionSource: hostSession),
  models: [],
  builtInTools: const [
    PresentationTool(kind: AssistantCardKind.summary),
    PresentationTool(kind: AssistantCardKind.selection),
  ],
);
```

`gatewayUri`, `hostSession` and `assistant` are host-owned objects. An empty model list delegates the catalog to the server. Optional built-in tools are enabled only when included; remove one from the list to disable it on the next initialization. Duplicate tool names are rejected.

## Authentication bridge

`SessionSource` provides:

- `identity`: stable identity of the current login, or null after logout.
- `changes`: a stream that emits whenever the authentication context changes.
- `issueTicket()`: obtains a fresh single-use signed JWT from the product backend.

`CallbackSessionSource` adapts existing authentication callbacks. The backend derives tenant, user and login ID from its verified session, never from arbitrary frontend fields. It signs the short-lived ticket using the product-specific secret shared with the gateway. Flutter never stores this signing secret or a provider key.

The gateway exchanges a ticket for an opaque credential valid for at most ten minutes and no longer than the host session. Before inference, the transport renews a credential approaching expiry by requesting another ticket. Rotation preserves the registered tools and daily budget. A login identity change cancels pending local actions and clears the conversation; use the Connect assistant action to register the current identity again. Create a new assistant instance to replace its transport or configuration.

Call `GatewayTransport.revokeSession()` before discarding a logged-in transport when server-side revocation is required. Local `dispose()` alone does not revoke a remote credential. The product must use a new login ID after revocation.

## Local tools

`AsystantTool` exposes `definition`, `preview`, `execute`, `requiresConfirmation`, `requiresSelection` and `isAvailable`. `TypedAsystantTool<T>` adds a single domain decoder and typed preview/execution methods. Schema validation rejects unknown fields and wrong scalar types before execution.

A preview must be read-only. Mutating actions require confirmation by default. The model cannot approve its own action. Check `ToolContext.isCanceled` or `checkCanceled()` immediately before an asynchronous write, and use its `idempotencyKey` in your own repository. Existing product authorization is still mandatory; a model-requested action is not an authorization grant.

The SDK bounds each user turn to eight inference rounds and sixteen calls per response. It does not automatically retry uncertain writes or reverse effects already committed. Tool result text returns to the model; optional cards remain in chronological order in the chat.

## Embedding and customization

`AsystantButton` opens a bottom sheet. `AsystantChat` is a bounded section without its own app router or Scaffold; use it in drawers, panels and full screens. Colors follow the host theme. `AsystantTheme` controls dimensions. `AsystantStrings(spanish: false)` selects English; the default locale-aware widget path supports English and Spanish, and subclassing allows custom wording.

GenUI supports summary, entity, selection, permission and result cards. Selections use stable option strings that tools can map to host domain identifiers. Tool steps show preparing, permission, running, completed, declined, canceled and failed states.

## Backend compatibility

Use the [Rust reference implementation](../services/asystant_gateway/README.md) directly or as guidance for a compatible service. The authoritative request/response contract is [OpenAPI](../services/asystant_gateway/openapi.yaml), including SSE envelopes and errors. See [security](../SECURITY.md) before exposing a deployment.

Model policy precedence is user, then tenant, then product. Initialization returns `models`, `default_model` and `allow_selection`. A fixed assignment disables the picker and rejects a forged model selection server-side on every inference. Configuration changes require a gateway restart; removed models require clients to reinitialize.

### Deferred startup

`init()` only stores configuration. It does not evaluate application tool getters,
create a session, or contact the gateway. `AsystantChat` starts setup after its first
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
  transport: gateway,
  additionalSystemPrompts: const [
    AsystantSystemPrompt(id: 'workspace.context', content: 'Reply in English.'),
  ],
  builtInTools: const [ChartPresentationTool()],
);
```

`AsystantPromptPolicy.security` is always first. Duplicate IDs, empty instructions,
and replacement of the reserved security ID are rejected. Up to 15 application
prompts may supplement the baseline. The gateway independently applies the same
baseline for clients that bypass the Flutter SDK, across all provider adapters.
The baseline treats retrieved content and tool output as untrusted, prohibits
claiming approval or successful writes without evidence, and instructs the model
not to disclose secrets. It is guidance, not a guarantee against prompt injection.
Never put secrets into prompts; authorization, validation and confirmation remain
mandatory application/server responsibilities.

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
