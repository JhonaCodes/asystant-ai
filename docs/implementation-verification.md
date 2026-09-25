# Implementation verification

## Scope and context

The implementation is a reusable Flutter assistant inside an existing app, distributed as `asystant_ai` with its pure-Dart dependency `asystant_core`. The Rust gateway is a separate self-hosted service. The host chooses the display name, tools, instructions and authentication bridge. Reference applications were inspected read-only and were not modified.

## Business rules

Tools execute locally. Writes require confirmation by default. Denial, cancellation and identity changes invalidate pending approvals; host repositories must still enforce their own authorization and idempotency. The gateway verifies short-lived single-use tickets and records only hashes of opaque credentials. Model policy precedence is user, tenant, product, enforced again for every inference. Durable budget reservations survive token renewal and process restarts.

## Verification evidence

The implementation baseline passed seven Dart tests, thirteen Flutter/example tests and eight Rust tests. These cover schema validation, credential renewal, malformed responses, truncated SSE, permission decisions, cancellation, independent assistants, responsive layouts, concurrent reservations, persistent revocation and client model assignment. The opt-in live-provider test is excluded without explicit credentials.

Publication preparation additionally introduces admission tests for exchange limits, peer separation and spoofed forwarding headers, extends HTTP coverage for public OpenAPI and closed request DTOs, and checks concurrency rejection before inference. The release record records the final executed checks rather than treating documentation as proof.

Earlier native builds passed Android debug, iOS Simulator debug and macOS debug. Web release and browser checks cover the actual embedded example. Windows and Linux are supported by the Dart/Flutter code and generated host projects but were not natively built on this macOS host.

Docker verification uses disposable PostgreSQL, a non-root process and read-only root filesystem. Readiness fails before migration, succeeds afterward and fails on database outage while liveness remains available. Production hosting has not been performed.

## Package distribution

MIT licenses, English usage guides, examples, changelogs, metadata and API comments are included in both packages. Publication checks use `pana` and `pub publish --dry-run`. Official pub.dev scores are produced asynchronously by pub.dev and must be distinguished from local analysis. Repository access and the publication order of the core dependency affect those results.

## Security posture

The [security policy](../SECURITY.md) maps implemented controls to OWASP API Security Top 10 concerns and specifies operator responsibilities. Local code/tests are not an external penetration test or an OWASP certification. Shared ingress abuse controls, TLS, database permissions, backups and monitoring must be configured for the actual deployment.

## Remaining limits

- The available OpenRouter development credential returned HTTP 401; no successful external inference is claimed.
- Each product must implement ticket issuance using its real existing login.
- Messages/Responses adapters return complete responses, not incremental text.
- Pending uncertain usage requires manual provider reconciliation; no automatic reconciliation or retention worker exists.
- Cancellation cannot reverse already committed application effects.
- Model/budget configuration changes require restart; removing a model may require client reinitialization.

The SDK can be published and integrated with these limits documented. A production service is not declared validated until its provider, product authentication and deployment controls have been verified.

## Release preparation checks

The English host example was built for web and exercised at 1280 px and 390 px; screenshots were refreshed. The complete local Dart/Flutter suite passed after formatting and documentation changes. Ten Rust tests passed with the selected AWS-LC JWT backend and HTTP/1 server features. `cargo audit` reported zero known advisories and zero warnings for the resulting lockfile. Clippy passed with warnings denied. OpenAPI 3.1 validation passed.

The process-local admission tests reject forged forwarding-header bypasses; the HTTP test verifies that concurrency rejection leaves the request ID available for a subsequent successful inference. Provider response reads now enforce the byte limit while streaming rather than after buffering the entire body. A whole-inference deadline also bounds slow consumer backpressure.

The disabled optional HTTP/2 server feature removed the affected `h2` dependency; the ingress can still terminate HTTPS/HTTP2 and forward HTTP/1. Switching the supported JWT crypto backend removed the affected `rsa` dependency without changing the HS256 ticket contract. These checks apply to the committed dependency selection, not to all future releases or the deployment operating system.
