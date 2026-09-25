# SDK security policy

This repository contains the Flutter SDK. The independently deployed Rust API
and its OWASP-mapped controls are maintained in
[asystant-gateway](https://github.com/JhonaCodes/asystant-gateway/blob/main/SECURITY.md).
Historical verification reports in this repository describe the earlier bundled
PostgreSQL gateway; they are not deployment instructions for the SQLite service.

## Reporting

Report SDK vulnerabilities privately through
[GitHub private vulnerability reporting](https://github.com/JhonaCodes/asystant-ai/security/advisories/new).
Do not include credentials or customer data in public issues.

## Host application responsibilities

- Issue gateway tickets only after the product backend verifies the active login.
  Derive tenant, user and session identity on the server; never trust caller-selected identities.
- Keep provider keys and product signing secrets outside Flutter. The SDK uses
  temporary gateway credentials and refreshes them through the host session.
- Register and execute application tools locally. Recheck authorization and the
  captured session before mutations; request explicit confirmation when needed.
- Treat model text and tool results as untrusted. Never execute returned code or
  render arbitrary HTML. Security prompts are guidance, not authorization.
- Closing the chat preserves work while the app process is active. Logout or an
  identity change must invalidate the conversation and pending permissions.
- Do not automatically replay uncertain mutations. Reconcile accepted operations
  using product-owned idempotency records and business services.
- Apply platform-appropriate link validation, storage protection and lifecycle rules.

The SDK provides typed tools, confirmation UI, bounded inference rounds and local
session controls. Product-specific authorization, provider policy, ingress and
operational security remain responsibilities of their respective applications.
No package score constitutes an OWASP certification or penetration test.
