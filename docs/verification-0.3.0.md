# Verification — asystant_ai 0.3.0

This release adds `cardContentBuilder` to the Flutter chat and launcher. Core and
Rust gateway wire contracts are unchanged.

- Context: typed, host-owned result presentations are needed for domain artifacts
  such as a public QR with an explicit download button.
- Business rules: only completed tool entries invoke the builder. Pending
  permission cards retain the SDK's approval and denial controls.
- Code quality: additive callback, no new dependency, transport or global state.
- Tests: Flutter analyzer clean; 34 SDK tests passed and one credential-dependent
  live test skipped. Existing English golden baselines passed unchanged.
- Confidence: high for callback wiring, explicit interaction and consent isolation.
- Independent audit: GO for the SDK extension.
- Residual limits: builders are trusted host code; they must avoid side effects
  during build. Persistence and restoration of host card subclasses remain the
  host's responsibility. No new live-provider claim is made by this release.
