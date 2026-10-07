# asystant_ai — architecture

A map for a new contributor. For the full public API, see dartdoc.

## Modules

```mermaid
flowchart TD
  Host[App host] -->|extiende| AI[AsystantAI<br/>fachada publica]
  AI -->|mixin| SVC[AsystantService<br/>contenedor perezoso]
  SVC -->|crea sin parametros| VM[ChatViewModel]
  VM -->|unico estado| ST[ChatState]
  VM -->|habla con| CORE[asystant_core<br/>transport + tools]
  UI[AsystantChat<br/>un solo builder] -->|lee| ST
  UI -->|invoca metodos| VM
  W[39 widgets<br/>solo presentacion] -->|reciben datos| UI
  CORE --> PROV[Providers:<br/>OpenRouter / ClaudeCode]
  CORE --> TOOL[Tools tipadas]
  AI -.->|refreshProvider con guardas| VM
  SHEET[Provider settings sheet] -.->|llama| AI
```

## State flow

```mermaid
stateDiagram-v2
  [*] --> idle
  idle --> initializing: configure()
  initializing --> ready: transporte listo
  initializing --> error: fallo de red
  error --> initializing: reintento
  ready --> thinking: send()
  thinking --> executing: el modelo pide una tool
  thinking --> done: respuesta sin tools
  executing --> permission: la tool requiere aprobacion
  permission --> executing: approve(true)
  permission --> canceled: approve(false)
  executing --> thinking: resultado al modelo
  executing --> done: turno terminado
  done --> ready: listo para el siguiente
  thinking --> canceled: stop()
  canceled --> ready
```

## Layering

- `AsystantAI` is the public facade a host extends. `AsystantService` is the
  mixin that lazily owns one `ChatViewModel` per instance.
- `ChatViewModel` holds the one `ChatState` for a conversation and talks to
  `asystant_core` for transport and tool execution.
- `AsystantChat` is the single `ReactiveViewModelBuilder` of the package: it
  reads `ChatState` and invokes `ChatViewModel` methods. Every other widget
  under `widgets/` is pure presentation — it receives already-derived data
  and renders it, nothing more.

## Rules

- All business logic lives in the `ChatViewModel` (or in the `ChatState`
  getters it exposes) — never in a widget's `build()`. A condition that is
  not strictly visual is in the wrong layer.
- `ChatViewModel` has a zero-parameter constructor. Collaborators are
  resolved inside via `configure(...)`, never injected through the
  constructor.
- One `ReactiveViewModelBuilder` per screen, never nested. `AsystantChat`
  owns the only one in this package.
