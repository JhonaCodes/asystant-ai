## Unreleased

- `ToolContext.reportProgress(fraction, label: ...)`: a long tool reports how far it has come (0 to 1, clamped; non-finite values ignored) with an optional short label for the person. The context forwards it to an optional `onProgress` (`ToolProgressListener`) given by whoever runs the tool; it never reaches the model and does nothing once the call is canceled.
- Local knowledge (RAG): `AsystantKnowledge`, a local index of `KnowledgeDocument`s (id, title, text, optional collection, tags and metadata) with `put` (add or replace by id), `putAll`, `remove` and `clear`. It ranks with BM25 over title, tags and text, normalized for Spanish and English (lower case, accents folded, stop words of both languages, light plural and gender stemming, prefix matching for query words of four letters or more), filters by collection and tags, and returns `KnowledgeHit`s with the most relevant passage instead of the whole document. `toJson` / `fromJson` save and restore it; the app decides where. Lexical by design: no service, model or dependency, and deterministic.
- `KnowledgeRetriever`: the contract the search tool and apps depend on (`search(KnowledgeQuery)`, `collections`), so a semantic or hybrid retriever can replace the lexical index later without changing the apps.
- `KnowledgeSearchTool`: an optional built-in, read-only tool (`search_knowledge` by default, configurable) that the model calls with `query`, an optional `collection` and `limit`, and that answers with compact JSON: `id`, `title`, `collection`, `score` and `snippet` per hit. It works the same with every provider.
- `ToolOutcome.images`: a tool can return images (PNG, JPEG, GIF, WebP bytes as `AsystantAttachment`s) for the model to look at, such as a rendered frame for visual self-review. They are kept as the `attachments` of the tool's result message, next to the person's own attachments.
- `AssistantTransport.supportsImageInput(model)`: a provider-neutral capability, false by default. A transport that cannot send images sends `AsystantAttachment.imageUnavailableNote` instead. Custom transports that send images override it.
- `OpenRouterTransport`: a tool's images follow its results as one `user` message after the last consecutive tool result, labelled with the `call_id`, because OpenRouter only accepts text in `tool` messages. Images for a model without image input are sent as the note.
- `ClaudeCliTransport`: stdin is now one `--input-format stream-json` user message, the transcript followed by base64 `image` blocks, so the person's images and a tool's images reach the model; previously images were only announced by name. `ClaudeCliProtocol.input` builds it. Tools, context, `endsTurn`, cancellation and the isolation flags are unchanged.
- `ToolOutcome.endsTurn`: a tool can end the person's turn (for example, a product approval that only the person can answer). The chat does not call the model again and answers the other calls of that response without running them.
- `ToolOutcome.summary` (a one-line account of what was done, shown instead of the preview title once the tool completes) and `ToolOutcome.data` (structured result for the host, never sent to the model).
- `ToolField.options` declares the accepted values of a string (schema `enum`), and `ToolFieldKind.objects` with `ToolField.fields` declares a list of objects with their own fields. Both providers send them in the tool schema.
- `ToolRegistry.resolve` explains what is wrong in the failure `detail` (unknown tool with the available ones, missing or unexpected argument, wrong type, a value outside its options), and treats `null` for an optional argument as absent.
- `AssistantTransport.infer` receives `tools`, the tools available for that request; both providers declare those instead of the ones registered at `initialize` when given. Custom transports must add the parameter.
- `OpenRouterTransport` replaces the former `GatewayTransport` and `SessionSource`: the host supplies an `OpenRouterCredentialSource` (for example a budget-limited key issued by asystant-api) and the transport talks to OpenRouter directly.
- Security: a cached OpenRouter key is bound to the identity it was issued for; after a login change the transport requests a new key instead of reusing the previous user's.
- `ClaudeCliTransport`: a desktop transport over the local Claude Code CLI, using the user's subscription without an API key. Tools are declared in the system prompt and returned as regular `ToolCall`s; the CLI's own tools, MCP servers and user customizations are disabled. Compiles on the web, where it reports the platform as unsupported.
- Providers: the sealed `AsystantProvider`, with `OpenRouterProvider` and `ClaudeCodeProvider`, is how an assistant chooses where answers come from. Each variant implements `createTransport()`; `verify()` and `modelCatalog()` work for any provider. Each provider lives in `src/providers/<name>/` with everything it needs; adding one changes no other provider or common code (see "Adding a provider" in `docs/public-api.md`). Public imports are unchanged.
- `AssistantTransport.verify()` and `AssistantTransport.modelCatalog()`, with defaults that report them as unsupported, return the provider-neutral `AsystantProviderStatus` and `AsystantModelCatalog`.
- `ClaudeCodeProvider` / `ClaudeCliTransport`: `verify()` runs `claude --version` and `claude auth status --json` (no inference) and reports version, sign-in and plan, never the email; `modelCatalog()` reads the models and effort levels from `claude --help`, falling back to `ClaudeCliCatalog.bundled`. With no models, `initialize` offers that catalog (`ClaudeCliTransport.defaultModels` is replaced by `ClaudeCliCatalog.bundledModels`). New `defaultModel`. The CLI runs with its own directory first on `PATH`, so an npm install finds `node` from a Finder-launched app.
- `ClaudeCliLauncher.run` runs short commands that send no prompt; custom launchers must implement it.
- `OpenRouterProvider` / `OpenRouterTransport`: `verify()` checks the key with `GET /api/v1/key` (no inference); `modelCatalog()` lists the credential's allowed models.

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
- Flutter-independent models, transport contracts and SSE gateway client.
