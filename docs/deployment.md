# Deployment

The Flutter SDK has no server component to deploy. `OpenRouterTransport` calls
OpenRouter directly from the app; `ClaudeCliTransport` runs the Claude Code CLI on
the user's desktop.

For OpenRouter keys with per-tenant and per-user budgets, deploy
[asystant-api](https://github.com/JhonaCodes/asystant-api), maintained separately.
It is a Rust service with SQLite on a persistent `/data` volume. Your backend calls
its `POST /v1/managed/credentials` and hands the response to the app, which reads it
with `OpenRouterCredential.fromManagedJson`. Follow its
[deployment guide](https://github.com/JhonaCodes/asystant-api/blob/main/docs/deployment.md)
and [API contract](https://github.com/JhonaCodes/asystant-api/blob/main/openapi.yaml).

The earlier ticket/session gateway, its PostgreSQL deployment and the SDK's former
gateway transport no longer exist; asystant-api 0.3.0 removed that flow. Historical
verification reports in this directory describe it.
