# SDK 0.2.0 verification

> Historical document: gateway source now lives in [asystant-gateway](https://github.com/JhonaCodes/asystant-gateway). PostgreSQL details and monorepo commands below describe the earlier bundled version.

## Context

The Flutter SDK remains an embeddable assistant using reactive_notifier. Tool
execution stays inside the host app. The independent Rust gateway owns credentials,
provider access, per-client model policy and durable budgets. Examples and primary
prompts are English; both packages and the gateway retain MIT licensing.

## Business rules

Configuration performs no tool registration or network request. Mounting the chat
starts deferred setup after its first frame; concurrent opens share one operation.
Disposal cancels pending setup and releases the transport exactly once. Failed
setup has an explicit retry, without replaying messages or writes. A new assistant
instance is required to replace configuration.

Default prompt safeguards supplement host instructions. They cannot substitute for
permission checks. Charts render a bounded typed series, label values and source,
and never execute generated code. Existing confirmation and cancellation rules
still govern local application mutations.

## Code review

An independent Flutter/Rust review identified configuration replacement, unopened
transport cleanup, an ownership handoff race, uncaught registration exceptions and
missing retry for embedded chat. These findings were corrected and covered by tests.
Widgets were decomposed into small classes, imports/member layout normalized, and
provider serialization split into readable steps. No new runtime dependency was added.

## Tests executed

- Flutter analysis: no issues.
- Core Dart suite: 10 passed.
- Flutter/example suite: 22 passed, one opt-in external-provider test skipped.
- Rust contract, admission, prompt-policy, model-policy, database and HTTP suites:
  12 passed against an isolated local PostgreSQL database.
- Rust clippy: no warnings; cargo audit: no reported advisories.
- OpenAPI validator: passed.
- Docker build and deployment check: non-root/read-only execution, migration job,
  readiness and database-outage behavior passed with disposable resources.
- English mobile/desktop golden images generated and visually inspected.
- Core package local pana: 160/160. Package publication scores are recorded separately
  once pub.dev completes its own analysis.
- Candidate repository files checked against local secret values: no matches.

## Confidence

High confidence in local lifecycle, authorization boundaries, typed presentations
and container startup. Tests exercise deterministic HTTP fixtures and isolated
storage; they do not establish real-provider quality or production network behavior.

## Deployment decision

The gateway artifact is ready for a configured deployment and integration smoke test.
Supply dedicated PostgreSQL, HTTPS ingress, product signing configuration and a valid
provider key. Follow [deployment instructions](deployment.md). No production service
was deployed during these checks.

## Residual risks

The earlier OpenRouter credential returned HTTP 401. A successful live inference is
still required with a valid server-side key. Model quality/cost experience is attributed
to the project owner in [model experience](model-experience.md), not presented as an
independent benchmark. Prompts do not guarantee prevention of prompt injection.
