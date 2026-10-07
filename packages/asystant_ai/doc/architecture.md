# asystant_ai — architecture

A map for a new contributor. For the full public API, see dartdoc.

## Modules

```mermaid
flowchart TD
  Host[Host app] -->|extends| AI[AsystantAI<br/>public facade]
  AI -->|mixin| SVC[AsystantService<br/>lazy container]
  SVC -->|creates, no params| VM[ChatViewModel]
  VM -->|single state| ST[ChatState]
  VM -->|talks to| CORE[asystant_core<br/>transport + tools]
  UI[AsystantChat<br/>one builder] -->|reads| ST
  UI -->|calls methods| VM
  W[Widgets<br/>presentation only] -->|receive data| UI
  CORE --> PROV[Providers:<br/>OpenRouter / ClaudeCode]
  CORE --> TOOL[Typed tools]
  AI -.->|refreshProvider, guarded| VM
  SHEET[Provider settings sheet] -->|one builder| PVM[ProviderSettingsViewModel]
  PVM -.->|calls| AI
```

## State flow

```mermaid
stateDiagram-v2
  [*] --> idle
  idle --> initializing: configure()
  initializing --> ready: transport ready
  initializing --> error: network failure
  error --> initializing: retry
  ready --> thinking: send()
  thinking --> executing: model requests a tool
  thinking --> done: answer without tools
  executing --> permission: tool needs approval
  permission --> executing: approve(true)
  permission --> canceled: approve(false)
  executing --> thinking: result back to the model
  executing --> done: turn ended
  done --> ready: ready for the next turn
  thinking --> canceled: stop()
  canceled --> ready
```

## Layering

- `AsystantAI` is the public facade a host extends. `AsystantService` is the
  mixin that lazily owns one `ChatViewModel` per instance.
- `ChatViewModel` holds the one `ChatState` for a conversation and talks to
  `asystant_core` for transport and tool execution. Its code is split by
  responsibility into five private `part of` mixins, one file each:
  `lifecycle`, `conversations`, `composition`, `turn` and `tools`. Each mixin
  is declared `on` the ones applied before it, and every private member is
  implemented in exactly one of them.
- `ProviderSettingsViewModel` (private, not exported) owns the provider
  settings sheet: loading, validation, saving and key removal. `open()`
  resets it on every opening. The API key is only ever a method argument and
  never part of its state.
- `AsystantChat` is the single `ReactiveViewModelBuilder` of the chat: it
  reads `ChatState` and invokes `ChatViewModel` methods. Every other widget
  under `widgets/` is pure presentation; enum-to-glyph/color mappings live in
  the `*_presentation.dart` extensions.

## Rules

- All business logic lives in a view model or in the `ChatState` getters
  it exposes, never in a widget's `build()`. A condition that is not
  strictly visual is in the wrong layer.
- View models have a zero-parameter constructor. Collaborators arrive
  through a method (`configure(...)`, `open(...)`), never the constructor.
- One reactive builder per screen, never nested.
- Never call `ReactiveNotifier.cleanup()`: it is global and would wipe the
  host's state.
- Deferred design debt is marked in code with `keel-debt:` comments.
