## Unreleased

- Fix: pending permission cards no longer render host card content next to Authorize/Decline, as the card-content contract requires.
- `AsystantAI.init(provider: ...)` is the way to connect an assistant: `OpenRouterProvider`, `ClaudeCodeProvider` or any later `AsystantProvider`. Tools, prompts, per-request context, attachments, the model picker and cards work the same with each. `init(transport: ...)` remains for a custom `AssistantTransport` (test doubles, proxies); pass exactly one of the two.
- With `ClaudeCodeProvider` and no `models`, the chat offers the models the installed Claude Code CLI declares.
- The example answers through `ClaudeCodeProvider` with `--dart-define=CLAUDE_CODE=true` on a desktop, and through a simulated transport otherwise.
- Documentation describes the providers and how to add one; the gateway session API no longer exists.

## 0.3.2

- Align the embedded chat with Aula-AI: compact header, inline composer and icon-only send/stop controls.
- Isolate input borders from host themes and support Enter to send / Shift+Enter for a new line.
- Pulse the working icon while keeping status text readable; respect reduced-motion preferences.
- Refine bordered messages and discreet inline failure feedback.

## 0.3.1

- Render assistant controls, status indicators, and cards with bundled SVG icons,
  independent of Material icon font downloads and web font caches.
- Refine the chat header, message typography, composer, and failure feedback.
- Add English chat previews at mobile and desktop widths with no icon fonts loaded.

## 0.3.0

- Add host-owned content for completed GenUI cards through `cardContentBuilder`.
- Keep custom result widgets separate from SDK permission controls.

## 0.2.1

- Selectable conversation and card text with clickable links and host-controlled navigation.
- Batched streaming updates reduce UI notifications without interrupting hidden conversations.
- Regression coverage for closing/reopening during inference, pending approvals, and account changes.
- Documented session-owned conversation lifetime and explicit cancellation.

## 0.2.0

- Deferred Flutter initialization: `init()` stores configuration; the mounted chat connects after its first frame. Headless clients await `ensureInitialized()` explicitly.
- Injectable application/context prompts and baseline safety guidance in SDK and gateway.
- Typed genUI bar/line charts, bounded numeric tool arguments and English golden previews.
- Initialization retry, concurrent setup deduplication and lifecycle cleanup.

## 0.1.0

- Initial MIT-licensed release.
- Typed local tools, explicit permissions and cancellation-aware execution.
- Session-backed gateway authentication and server-assigned model policies.
- English examples and integration guidance for the reference Rust API.
- Embeddable Flutter chat, adaptive layouts, genUI cards and reactive_notifier state.
