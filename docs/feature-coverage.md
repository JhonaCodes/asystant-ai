# Feature coverage

| Requirement | Implementation |
| --- | --- |
| Flutter mobile, web and desktop | Shared bounded chat; a sheet on phones and a side panel on tablets and desktops through `AsystantButton`, or `AsystantChat` placed by the host |
| Configurable assistant name | `AsystantAI(name: ..., description: ...)` |
| Tools embedded in each app | Typed registry, local preview and execution, optional built-ins |
| Explicit permissions | Confirmation by default, optional required selection, cancellation-aware context |
| GenUI | Summary, entity, selection, permission and result cards, bar and line charts, host-owned card content |
| Progress and state icons | Tool steps, send/stop action and failure notices |
| Transport contract | `AssistantTransport`, implemented by `OpenRouterTransport` and `ClaudeCliTransport`, or by the host |
| Existing login integration | `OpenRouterCredentialSource` backed by the host backend, which obtains the user's key from asystant-api; `identity` and `sessionChanges` report login changes |
| Credential renewal | Credential cached until `refreshAfter`/`expiresAt`, then requested again; dropped on HTTP 401/403 |
| Model assignment | Host model list restricted to the credential's `allowedModels`; an empty list offers exactly those |
| Budgets | Enforced outside the SDK: asystant-api issues OpenRouter keys limited to the tenant/user budget |
| OpenRouter | Chat Completions streaming over SSE from the app, usage reporting, context window and input types per model |
| Claude Code CLI | Desktop transport over the user's local CLI and subscription, tools declared in the system prompt |
| Public API reference | [Integration guide](public-api.md), package READMEs and asystant-api's OpenAPI contract |
| MIT distribution | License at repository and package roots |

## Limits

The repository includes no hosted endpoint, provider key or inference credit. For `OpenRouterTransport`, each product must obtain users' keys from its own backend (for example through asystant-api) using its real login. `ClaudeCliTransport` works only on desktop, with the Claude Code CLI installed and signed in; on the web, iOS and Android it reports the platform as unavailable, and its tool calls depend on the model following the prompt's `<tool_call>` format.

There is no client-side key revocation: `dispose()` only forgets the cached key, and revocation belongs to asystant-api. A transport keeps its cached key until it must be refreshed, so a different user needs a new assistant instance.

Application authorization, idempotency and cancellation checks remain essential inside local tools. Already committed effects cannot be undone by stopping the chat. Windows/Linux builds need their corresponding build hosts; the release checks distinguish analyzed platform support from native build execution.
