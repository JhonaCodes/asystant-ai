# Architecture

The system separates application capabilities from provider access. Flutter owns the interaction, local permission decisions and tool execution. The gateway owns credentials, provider keys, model assignment and durable accounting. PostgreSQL stores credential hashes, consumed tickets, registrations, revocations and budget reservations.

A product backend verifies its existing session and signs a short-lived single-use ticket. The gateway exchanges it for an opaque credential. The SDK registers schemas and instructions, requests inference and dispatches validated proposed calls to local tools. Results return to the model in another inference round.

Rust/Actix and Diesel provide the server implementation, typed error boundaries and transactional reservations. Pure Dart contracts keep the tool model independent of Flutter. The Flutter package uses reactive_notifier per instance and composes the same chat within existing navigation.

OpenRouter is the initial provider with `openai/gpt-oss-20b`. Adapters normalize different wire protocols; they do not assume Anthropic Messages, OpenAI Responses and Chat Completions are interchangeable. Provider model availability and terms remain deployment configuration responsibilities.

Budget accounting reserves a conservative maximum before inference and settles a known cost once. Uncertain results keep their reservation pending until reconciled against the provider. A disconnected client does not grant a budget refund. No automated reconciliation worker or administration console is included in this release.
