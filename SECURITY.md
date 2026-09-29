# SDK security policy

This repository contains the Flutter SDK. asystant-api, the independently deployed
service that issues budget-limited OpenRouter keys, and its controls are maintained in
[asystant-api](https://github.com/JhonaCodes/asystant-api/blob/main/SECURITY.md).
Historical verification reports in this repository describe the earlier bundled
PostgreSQL ticket gateway, which no longer exists; they are not deployment instructions.

## Reporting

Report SDK vulnerabilities privately through
[GitHub private vulnerability reporting](https://github.com/JhonaCodes/asystant-ai/security/advisories/new).
Do not include credentials or customer data in public issues.

## Host application responsibilities

- Request a user's OpenRouter key (asystant-api `POST /v1/managed/credentials`)
  only after the product backend verifies the active login. Derive tenant and
  subject on the server; never trust caller-selected identities.
- Keep the asystant-api company key, provider management keys and any other
  long-lived secret outside Flutter. The app only receives the signed-in user's
  short-lived, budget-limited key through `OpenRouterCredentialSource`;
  `OpenRouterTransport` places it only in the `Authorization` header and redacts
  it from `toString()`. Never compile a key into a release build.
- `ClaudeCliTransport` runs the user's own Claude Code CLI with its tools, MCP
  servers and customizations disabled, and passes prompts through a private
  temporary file rather than the command line. It needs a desktop app allowed
  to start processes (on macOS, outside the App Sandbox).
- Register and execute application tools locally. Recheck authorization and the
  captured session before mutations; request explicit confirmation when needed.
- Treat model text and tool results as untrusted. Never execute returned code or
  render arbitrary HTML. Security prompts are guidance, not authorization.
- Closing the chat preserves work while the app process is active. Report logout
  or an identity change through the transport's `identity` and `sessionChanges` so
  the conversation and pending permissions are invalidated; create a new assistant
  for a different user. Key revocation happens in asystant-api, not in the app.
- Do not automatically replay uncertain mutations. Reconcile accepted operations
  using product-owned idempotency records and business services.
- Apply platform-appropriate link validation, storage protection and lifecycle rules.

The SDK provides typed tools, confirmation UI, bounded inference rounds and local
session controls. Product-specific authorization, provider policy, ingress and
operational security remain responsibilities of their respective applications.
No package score constitutes an OWASP certification or penetration test.
