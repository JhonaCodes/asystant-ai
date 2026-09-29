## Unreleased

- `OpenRouterTransport` replaces the former `GatewayTransport` and `SessionSource`: the host supplies an `OpenRouterCredentialSource` (for example a budget-limited key issued by asystant-api) and the transport talks to OpenRouter directly.
- Security: a cached OpenRouter key is bound to the identity it was issued for; after a login change the transport requests a new key instead of reusing the previous user's.
- `ClaudeCliTransport`: a desktop transport over the local Claude Code CLI, using the user's subscription without an API key. Tools are declared in the system prompt and returned as regular `ToolCall`s; the CLI's own tools, MCP servers and user customizations are disabled. Compiles on the web, where it reports the platform as unsupported.

## 0.2.0

- Deferred Flutter initialization: `init()` stores configuration; the mounted chat connects after its first frame. Headless clients await `ensureInitialized()` explicitly.
- Injectable application/context prompts and baseline safety guidance in SDK and gateway.
- Typed genUI bar/line charts, bounded numeric tool arguments and English golden previews.
- Initialization retry, concurrent setup deduplication and lifecycle cleanup.

## 0.1.0

- Initial MIT-licensed release.
- Typed local tools, explicit permissions and cancellation-aware execution.
- Session-backed gateway authentication and server-assigned model policies.
- English examples and integration guidance for the reference Rust API.
- Flutter-independent models, transport contracts and SSE gateway client.
