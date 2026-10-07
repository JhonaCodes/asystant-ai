## 0.7.3

- Add `showAsystantSecretPrompt` for one-time values collected on the device after an action's approval. The dialog returns values only to its caller and never adds them to conversation state.
- Keep the control-center chat, persistent conversations, native presentations and per-invocation sensitivity policy in the reusable package.

## 0.6.0

- Add `AsystantActionPolicy` and `AsystantSensitivity` so tools or the host assistant can classify each validated invocation by a host-defined name and color and decide whether it requires approval.
- Show sensitivity on approval cards and in the collapsible activity panel.
- Add **Approve all for this session** to eligible approval cards. It applies only to the current assistant login, never skips required selections, and is not persisted.

## 0.5.0

- Register any number of `AsystantPresentation` definitions on an assistant. Each definition provides its tool schema, input validation, trusted data resolution and completed-card widget.
- Persist presentation identity and data in conversation snapshots, so native cards survive app restarts; unknown presentations retain a generic card fallback.
- Include `AsystantChoicesPresentation` for questions with tappable answers.

## 0.4.3

- `AsystantChat.identityIcon` lets the host replace the default sparkle in the header with its own identity mark.
- `AsystantChat.welcomeContent` lets the host provide the empty conversation view while keeping the built-in timeline, activity steps, composer and permission flow.

## 0.4.2

- `AsystantChat.conversationActionsStyle`: `AsystantConversationActionsStyle.inline` (default, unchanged) or `.menu`, which puts the conversation list, new conversation and delete behind one icon as a dropdown, each entry with its own icon. `conversationMenuIcon` replaces the trigger icon.
- New dependency: `multiselect_field` ^2.5.0, used for the dropdown.

## 0.4.1

- `AsystantChat.headerActions`: host buttons in the header row, before the conversation actions, for hosts whose main screen is the chat itself (navigation, sessions, notifications).

## 0.4.0

- `ChatViewModel.reloadConversations()` keeps the conversation on screen in the store, then reads the list again and replaces the one shown with exactly what the store answers, newest first. For hosts whose store answers per context of their own (one list per open document): after switching the context, call it, then `openConversation` or `newConversation`. See the integration guide, "Host content".
- `AsystantAI.requiresConfirmation(tool)` decides whether a call waits for the person's approval. It is asked on every call, after the preview and before the tool runs, and defaults to the tool's own `requiresConfirmation`; a host overrides it to answer from its settings, such as a switch that approves everything. `ChatViewModel.configure` takes it as `confirmation` (`AsystantConfirmationPolicy`). It never skips `requiresSelection`.
- The images a tool returns (`ToolOutcome.images`) are also kept on its completed step (`AssistantStep.images`), and the built-in chat shows them as thumbnails under the step (`AsystantTheme.stepImageHeight`, 120 by default).
- Host content inside `AsystantChat`: `headerContent` (a widget under the header), `hostCards` (`AsystantHostCard`s pinned after the conversation, with `AsystantCardAction` buttons for decisions the host's workflow waits for) and `managesConversations` (off hides the conversation list, New and Delete, for hosts that keep one conversation per context). See the integration guide, "Host content".
- `AsystantStrings.failureMessage(failure)` words a failure in the chat; by default `failure(code)`, and a subclass can add the provider's detail.
- `GenUiCard` takes `actions`, drawn under the card's content.
- Progress of long tools: what a tool reports with `ToolContext.reportProgress` shows on its running step as `AssistantStep.progress` (0 to 1) and `AssistantStep.progressLabel`, with `AssistantStep.showsProgress`. `ChatViewModel` shows the first report at once and then at most one every 100 ms, always the latest, and ignores reports once the step ended or the turn was canceled. The built-in chat draws a thin bar under the running step. Canceling the turn still reaches the running tool through `ToolContext.isCanceled`, and its step ends as canceled.
- Local knowledge (RAG): pass `KnowledgeSearchTool(knowledge: AsystantKnowledge(...))` in `builtInTools` and the assistant searches the app's own documents, locally and without an embeddings model, with every provider (see asystant_core and the integration guide, "Local knowledge (RAG)").
- `AsystantAI.init(turnLimits: AsystantTurnLimits(...))` configures the limits of each turn, which were fixed: `maxRounds` inference rounds (8 by default, up to 64) and `maxCallsPerResponse` tool calls in one response (16 by default, up to 16, the built-in transports' own bound). Defaults and what happens at a limit are unchanged; an out-of-range value throws a `RangeError` from `init`. See the integration guide, "Turn limits".
- The images a tool returns (`ToolOutcome.images`) are kept on its result message and reach the model with every provider (see asystant_core).
- `AsystantTool.isAvailable` is read before every model call, not only at initialization: the model is offered the tools available at that moment, so a host can scope them to what it shows.
- A tool's failure `detail`, and the reason a call was rejected, reach the model with the tool result, so it can correct the call.
- `ToolOutcome.endsTurn` ends the turn after that tool (see asystant_core).
- `AssistantStep` records the `toolName`, when it `startedAt`, the `detail` of a failure and the tool's `data`; its title becomes the tool's `summary` when it completes. A conversation store keeps them with the entries.
- `ChatViewModel` is exported, for hosts that draw their own chat over `assistant.conversation`.
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
## 0.7.0

- Define the five tool sensitivity levels `none` (Nulo), `low` (Bajo), `medium` (Medio), `high` (Alto) and `admin` (Admin). Host tools assign a level for each validated invocation; the library provides its name, color and approval behavior.
- Run `none` and `low` actions immediately. Require approval for `medium`, `high` and `admin`, with the existing optional approval for the current session. Required selections always wait for the person.
- Move the tappable context usage meter into the chat header, leaving the composer free for input.
- Preserve the legacy `requiresConfirmation` behavior for tools that have not been classified yet.
## 0.7.1

- Remove the empty composer footer after moving context usage into the header.
## 0.7.2

- Show sensitivity as a compact colored ticket icon beside each action in the activity row; keep the localized level name in its tooltip and accessibility label.
- Place the compact context meter beside the chat header controls, with a full tooltip and tappable detail.
- Keep sensitivity identifiers and stored names in English while localizing their visible labels.
