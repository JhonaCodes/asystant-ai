# SDK 0.2.1 verification

## Context status

The change separates conversation execution from the visible chat panel and adds
link interaction and native text selection. The Rust gateway and core transport
contract are unchanged. `asystant_ai` 0.2.1 continues to depend on `asystant_core`
0.2.0. The host retains tools, identity and authorization ownership.

## Business-rule status

Hiding a chat preserves initialization, inference, approved asynchronous tool work
and history. Reopening observes the same operation without replay. Hidden approvals
wait for explicit user input. Stop, disposal and identity changes still invalidate
pending work. TurnosQR owns its conversation in a lazy ReactiveNotifier service;
the launcher does not initialize it during app startup.

## Code-quality findings

The independent review found no blocking correctness, ownership or security issue.
Provider text uses a StringBuffer and 32 ms state updates; terminal events clear
the timer, and an epoch guard rejects stale callbacks. Links require explicit
user interaction, reject unsafe schemes and embedded credentials, and show opening
failures inline. Image markup does not fetch external assets. Selection pauses
automatic scrolling, and partial streamed text avoids repeated Markdown parsing.

## Test verification

- Workspace Flutter analysis: no issues.
- Flutter package suite: 33 passed, one opt-in live-provider test skipped.
- Four background regressions verify hidden completion, retained approvals,
  account-change cleanup, batched updates and cancellation.
- Eight interaction tests exercise actual link taps, cross-message/card selection,
  keyboard clipboard copying, mobile Copy, navigation policy, failure feedback,
  image suppression and selection-aware scrolling.
- Existing English macOS golden images pass without replacement.
- Host example widget test: passed, including preserved draft after reopening.
- TurnosQR full suite: 133 passed, including five HTTP/SSE lifecycle regressions;
  its analyzer is clean. Hosted dependency validation follows publication.

## Confidence report

High confidence in in-memory conversation ownership, cancellation boundaries,
selection and link dispatch. Tests validate real widgets, production orchestration
and mocked HTTP/platform boundaries; they do not measure a universal frame-time
guarantee or prove every native operating-system/browser configuration.

## Go/No-Go

GO for the reviewed implementation. Publication and CI results are recorded in the
release. Production gateway configuration and provider acceptance requirements
remain in the deployment guide.

## Residual risks

Closing the panel differs from terminating or suspending the application process.
This implementation does not persist jobs across termination, reload or restart.
Async network I/O does not require an isolate. CPU-heavy custom tools must offload
their own pure computation to an appropriate worker; UI and service references
remain in the host isolate. Native `compute` is not a background worker on Flutter
web. Live provider inference still requires a valid deployment credential.
