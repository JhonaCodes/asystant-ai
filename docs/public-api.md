# Integration guide

## Assistant ownership

Extend `AsystantAI` in the host application. Override `tools` and optionally `systemPrompts`; pass any display name to the constructor. Own one instance per independent conversation. Closing the chat UI does not destroy it; call `dispose()` when its host owner is destroyed.

Initialize after the application services and login are ready. If initialization depends on mounted widgets, invoke it after the first frame; otherwise initialize before mounting the chat. Never rely on a frame callback as proof of authentication.

```dart
await assistant.init(
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

The gateway exchanges a ticket for an opaque credential valid for at most ten minutes and no longer than the host session. Before inference, the transport renews a credential approaching expiry by requesting another ticket. Rotation preserves the registered tools and daily budget. A login identity change cancels pending local actions and clears the conversation; initialize again for the new identity.

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
