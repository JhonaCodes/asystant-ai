# Feature coverage

| Requirement | Implementation |
| --- | --- |
| Flutter mobile, web and desktop | Shared bounded chat; host controls its navigation and placement |
| Configurable assistant name | `AsystantAI(name: ...)` |
| Tools embedded in each app | Typed registry, local preview and execution, optional built-ins |
| Explicit permissions | Confirmation by default, optional required selection, cancellation-aware context |
| GenUI | Summary, entity, selection, permission and result cards |
| Progress and state icons | Tool steps, send/stop action and failure notices |
| Existing login integration | `SessionSource` plus signed tickets from the product backend |
| Credential renewal | Short-lived opaque gateway token, renewed through current host session |
| Client model assignment | Product/tenant/user policies rechecked on every inference |
| Budgets | Transactional daily tenant/user reservations and durable settlement |
| OpenRouter | Chat Completions streaming, usage and configured price ceilings |
| OpenAI, Gemini, Anthropic, OpenCode | Provider-specific adapters; protocol depends on model |
| Public API reference | OpenAPI, deployment guidance, security scope and integration examples |
| MIT distribution | License at repository, package and Rust-service roots |

## Limits

The repository includes no hosted endpoint or provider credit. Each product must integrate ticket issuance with its own backend. Real external inference still requires a valid provider key; the development credential returned HTTP 401.

Messages and Responses adapters currently return a complete response instead of incremental text. The gateway has no public administration endpoint or automatic reconciliation worker. Configuration changes require restart. Rate limits inside the process supplement, rather than replace, trusted-ingress and multi-replica abuse controls.

Application authorization, idempotency and cancellation checks remain essential inside local tools. Already committed effects cannot be undone by stopping the chat. Windows/Linux builds need their corresponding build hosts; the release checks distinguish analyzed platform support from native build execution.
