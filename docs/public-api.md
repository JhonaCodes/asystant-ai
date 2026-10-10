# Integration guide

## Assistant ownership

Extend `AsystantAI` in the host application. Override `tools` and optionally `systemPrompts` and `contextPrompts()`; pass any display name, and an optional `description`, to the constructor. Own one instance per independent conversation. Closing the chat UI does not destroy it; call `dispose()` when its host owner is destroyed.

Configure the instance once with `init`, passing an `AsystantProvider` (see [Providers](#providers)). `init` only stores the configuration, so it can run before login completes; the chat connects later (see [Deferred startup](#deferred-startup)). Calling `init` a second time throws a `StateError`: create a new assistant instance to replace its provider or configuration.

```dart
assistant.init(
  provider: OpenRouterProvider(
    credentials: fetchAiCredential,
    identity: () => session.userId,
    sessionChanges: session.changes,
    appName: 'Workspace',
  ),
  models: const [
    AsystantModelOption(id: 'openai/gpt-oss-120b', label: 'Precise'),
    AsystantModelOption(id: 'openai/gpt-oss-20b', label: 'Fast'),
  ],
  builtInTools: const [
    PresentationTool(kind: AssistantCardKind.summary),
    PresentationTool(kind: AssistantCardKind.selection),
  ],
);
```

`assistant`, `session` and `fetchAiCredential` are host-owned; see [Credentials and sign-in](#credentials-and-sign-in). `models` are the choices shown next to the send button, each with the provider's model id, a label and an optional icon and description; the first one the transport permits is the default. An empty list lets the provider decide: `OpenRouterProvider` offers the models the credential allows, and `ClaudeCodeProvider` the models the installed CLI declares. Optional built-in tools are enabled only when included; remove one from the list to disable it for a new instance. Duplicate tool names are rejected. For private values typed in chat, see [Private values in chat](../packages/asystant_ai/README.md#private-values-in-chat).

`init` also accepts `additionalSystemPrompts`, a `conversationStore` (an `AsystantConversationStore`; the default `InMemoryConversationStore` forgets conversations when the app closes), an `attachments` policy (`AsystantAttachmentPolicy`, every file type by default) and `turnLimits` (`AsystantTurnLimits`, see [Turn limits](#turn-limits)). Set `attachments: const AsystantAttachmentPolicy(rejectLikelySecrets: true)` to refuse readable text files containing likely credentials before they enter the chat. This opt-in guard also applies to custom pickers and programmatic attachments; images, PDFs and encoded content are not inspected.

`enableInlinePrivateInput` defaults to `true`. A local tool can call `context.requestPrivateInput(title, fields)` with any number of `PrivateInputField`s after its approval. The chat shows an inline card for passwords, codes, TOTP and other private inputs; values return only to the local tool, and its subsequent output is withheld from the model. The request metadata is ephemeral, and the values are not saved with the conversation. Set `enableInlinePrivateInput: false` when a host app must hide this feature; check `context.supportsPrivateInput` before calling it if the tool has a fallback UI. The host still owns secure credential storage and should not echo submitted values in logs or exceptions.

## Providers

A provider says where the answers come from. Everything else in the assistant (tools, system prompts, per-request context, attachments, the model picker, permissions and cards) is the same for every provider: it only talks to the `AssistantTransport` the provider creates.

| Provider | When to use it | What it needs | Platforms |
| --- | --- | --- | --- |
| `OpenRouterProvider` | Direct inference through OpenRouter | A `credentials` callback returning a local or server-issued provider key | Android, iOS, web, macOS, Linux, Windows |
| `OpenAICompatibleProvider` | An HTTPS Chat Completions endpoint | A `credentials` callback, base URL and model ID | Android, iOS, web, macOS, Linux, Windows |
| `ClaudeCodeProvider` | A local desktop app for someone who has Claude Code, such as a personal tool | The `claude` CLI installed and signed in with the person's subscription; no key, no backend | macOS, Linux, Windows |

```dart
// A published app: the key comes from your backend.
assistant.init(
  provider: OpenRouterProvider(credentials: fetchAiCredential, appName: 'Workspace'),
);

// A local desktop app: Claude Code is already signed in.
assistant.init(
  provider: const ClaudeCodeProvider(defaultModel: 'sonnet'),
  models: const [
    AsystantModelOption(id: 'sonnet', label: 'Sonnet'),
    AsystantModelOption(id: 'opus', label: 'Opus'),
  ],
);
```

Every provider answers two questions without running an inference, for a settings screen:

- `provider.verify()` returns an `AsystantProviderStatus`: the provider's name, `signedIn` (null when it cannot tell), the version of a local program and a non-secret account description; `isReady` summarizes it. It is an `Err` with a typed `FailureCode` when the provider cannot be reached at all.
- `provider.modelCatalog()` returns an `AsystantModelCatalog`: model ids, effort levels, `isOpenList` (other ids are accepted too) and `source` (`live`, or `bundled` with the SDK).

`AsystantProvider` is sealed, so a host can `switch` over the variants it knows, for example to show provider-specific settings. `init(transport: ...)` remains for an `AssistantTransport` of your own, such as a test double or a proxy; pass exactly one of `provider` and `transport`. The examples use providers.

### How each transport works

Each `infer` streams `TextDelta`s, an optional `UsageReported` and one `InferenceCompleted` whose `message.calls` holds the proposed tool calls, or an `InferenceFailed`. `initialize` registers the tool schemas and prompts and returns the permitted models. A transport never executes a tool.

- `OpenRouterProvider` creates an `OpenRouterTransport`, which calls OpenRouter's Chat Completions API directly from the app, streaming over SSE, using the key returned by the host credential callback.
- `ClaudeCodeProvider` creates a `ClaudeCliTransport`, which runs the Claude Code CLI installed on the user's machine, for local apps without a login or API key. It is always authenticated with a fixed `identity`.

`OpenRouterProvider` sends `appName` as `X-Title` and `appUrl` as `HTTP-Referer`, so usage is attributed to the app in OpenRouter. `baseUri` overrides the API root for an OpenRouter-compatible proxy. `maxOutputTokens` and `temperature` are passed through when set. `pdfEngine` chooses how attached PDFs are read (`pdf-text` by default, `mistral-ocr` or `native`). On initialization it reads each permitted model's context window, which feeds the chat's context meter, and the input types it accepts. HTTP failures map to typed `FailureCode`s: 401/403 to `authentication`, 402 to `budget`, 429 to `rateLimited`, a context overflow to `contextFull`, and 5xx to `unavailable`. `verify()` asks OpenRouter about the key (`GET /api/v1/key`).

`ClaudeCodeProvider` makes one stateless `claude -p` run per inference: the whole conversation, tool calls, results and images included, goes on stdin as one stream-json message, and the system prompt, with the per-request context and the tool catalog, goes through a private temporary file. No prompt text is placed on the command line. The CLI keeps no session (`--no-session-persistence`), because the SDK owns and may rewrite the history. Tools are declared in the system prompt, and the model writes each call as a `<tool_call>` JSON block that the transport turns into a `ToolCall`, so the SDK cannot tell it from a native tool call. The CLI's own tools, MCP servers and the user's Claude Code customizations are disabled. `verify()` runs `claude --version` and `claude auth status --json`; `modelCatalog()` reads `claude --help`. A missing binary fails with `FailureCode.unavailable` and a `detail` that says what to install; on the web, iOS and Android every call fails the same way. See the [asystant_core guide](../packages/asystant_core/README.md#claude-code-desktop) for models, isolation, attachments and cancellation.

### Images

Images reach the model by the same path whether the person attached them or a tool returned them (`ToolOutcome.images`): they are the `attachments` of an `AssistantMessage`, and each transport translates them. `transport.supportsImageInput(model)` says whether a model sees them; when it does not, each image is sent as the text of its `AsystantAttachment.imageUnavailableNote`, `[Image not available for this provider: "frame.png" (image/png, 1234 bytes, id …)]`, so the model knows an image was there and can pass its id to a tool.

- `OpenRouterProvider`: supported when the model's `input_modalities` include `image`. The person's images are `image_url` parts of their message. OpenRouter's API only accepts a string as the content of a `tool` message, and content parts such as `image_url` only in `user`, `assistant` and `system` messages ([API reference](https://openrouter.ai/docs/api-reference/overview)), so a tool's images cannot go inside its result: the result says they follow, and one `user` message placed after the last consecutive tool result carries them, each labelled with its `call_id`. It goes after the whole run of results because OpenAI-compatible APIs reject anything between the results of one response.
- `ClaudeCodeProvider`: supported for every model. stdin is one `--input-format stream-json` user message: the transcript as text, then one base64 `image` block per image, labelled as the transcript names it. PNG, JPEG, GIF and WebP up to 5 MB are sent; other images as their note.

## Adding a provider

A provider is self-contained: its folder holds everything it needs, and adding one changes no other provider, no common logic and no host code. In `packages/asystant_core/lib/src/providers/`:

1. **Create its folder**, `providers/<name>/`, with its transport, a class that `extends AssistantTransport` (`initialize`, `infer`, `cancel`, `dispose`, `isAuthenticated`, `identity`, `sessionChanges`), and whatever it needs: codec, stream decoder, launcher, credentials. Override `verify()` and `modelCatalog()` so settings screens can test it and list its models; override `contextLengthOf` and `defaultModel` when the provider knows them. Compose the prompts with `AsystantPromptPolicy().compose(prompts)` in `initialize`, and send `[...prompts, ...context]` on every `infer`, so the security baseline and the per-request context reach the model.
2. **Declare its variant** in `providers/<name>/<name>_provider.dart`, starting with `part of '../asystant_provider.dart';`: a `final class <Name>Provider extends AsystantProvider` with its settings, `name` and `createTransport()`. Dart requires the variants of a sealed class to be in its library, hence the `part`; a part cannot import, so its types come from the import added in step 4.
3. **Write its export file**, `providers/<name>/<name>.dart`, exporting the provider's public types (its transport and anything a host configures).
4. **Register it** with two lines in `providers/asystant_provider.dart`, `import 'package:asystant_core/src/providers/<name>/<name>.dart';` and `part '<name>/<name>_provider.dart';`, and one in `lib/asystant_core.dart`, `export 'package:asystant_core/src/providers/<name>/<name>.dart';`. `asystant_ai` re-exports `asystant_core`, so apps see the new provider after upgrading, with no other change.

**Images.** Messages carry images as `attachments` (see [Images](#images)): the person's on `user` messages, a tool's (`ToolOutcome.images`) on `tool` results. A transport whose provider accepts images sends them in that provider's format and overrides `supportsImageInput(model)` to return true for the models that see them. One that does not keeps the default, false, and sends each image as the text of `AsystantAttachment.imageUnavailableNote` instead, never silently dropping it. Nothing outside the provider's folder changes either way.

A variant without `createTransport()` does not compile, and nothing else dispatches on the provider type, so there is no switch to extend. Hosts that `switch` over `AsystantProvider` get a compile error listing the new variant, which is the intended signal.

## Credentials and sign-in

There are two independent ways to connect the chat. The host chooses which ones to expose; neither requires a particular backend product.

### Manual key on the device

Enable `AsystantProviderSettings(namespace: ...)` in `AsystantAI.init` and pass a host provider for the default `backend` choice. The library-owned settings sheet accepts a key, provider, optional HTTPS base URL for a compatible endpoint, and the primary model ID. It writes the key to platform secure storage, never into a message or conversation snapshot. Use a stable namespace scoped to the signed-in account; do not share one namespace between users. `availableKinds` limits the provider choices, and `showInChatMenu: false` hides the settings entry. Do not prefill a release build with a secret using `--dart-define` or another compiled constant.

```dart
assistant.init(
  provider: OpenRouterProvider(credentials: fetchServerCredential),
  providerSettings: AsystantProviderSettings(
    namespace: 'example:$accountId',
    availableKinds: const [
      AsystantProviderKind.backend,
      AsystantProviderKind.openRouter,
      AsystantProviderKind.openAi,
      AsystantProviderKind.compatible,
    ],
  ),
);
```

The local choices support OpenRouter and HTTPS OpenAI-compatible Chat Completions endpoints, including built-in OpenAI, Gemini and Claude API presets. The endpoint must support the requested model, streaming responses and OpenAI-style tool calls if the assistant uses tools. An OpenAPI document is a REST contract description, not the inference protocol. Claude Code CLI authentication is a separate desktop provider and is not a mobile API key.

### Credential issued through the host server

The host app authenticates its user by whatever account system it already uses. Its credential callback calls an authenticated endpoint on the host server and maps the response to the SDK credential type. For OpenRouter and OpenAI-compatible endpoints, that type is `OpenRouterCredential`, even when the actual provider is not OpenRouter:

```dart
Future<Result<OpenRouterCredential, AssistantFailure>> fetchServerCredential() async {
  final reply = await hostApi.issueAiCredential(); // An authenticated host API call.
  if (!reply.authorized) {
    return Err(const AssistantFailure(.authentication));
  }
  return Ok(OpenRouterCredential(
    apiKey: reply.providerToken,
    allowedModels: reply.allowedModels,
    expiresAt: reply.expiresAt,
    refreshAfter: reply.refreshAfter,
  ));
}

assistant.init(
  provider: OpenRouterProvider(
    credentials: fetchServerCredential,
    identity: () => account.id, // null while signed out
    sessionChanges: account.changes,
  ),
  models: const [], // Offer only models allowed by the credential.
);
```

For another HTTPS Chat Completions provider, use `OpenAICompatibleProvider(credentials: fetchServerCredential, baseUri: providerApiRoot, providerName: 'Example AI', model: selectedModel, identity: ..., sessionChanges: ...)`. Supply exactly one of `provider:` or `transport:`. A custom `AssistantTransport` is the integration point for a server-side inference proxy or a provider whose protocol is not compatible.

The server response has no mandatory JSON field names: the host callback maps its own response to `apiKey`, `allowedModels`, `expiresAt` and `refreshAfter`. `OpenRouterCredential.fromManagedJson` is only a convenience adapter when a response already uses its expected `api_key`, `allowed_models`, `expires_at` and `refresh_after` fields. A successful callback returns `Ok(credential)`; authentication, quota or network failures return a typed `Err(AssistantFailure(...))` without including tokens in error details.

The host server should authenticate every request, authorize the requested account or tenant, restrict models and spending, issue a short-lived credential that can be revoked or rotated, and rate-limit issuance. Keep any long-lived provider master key on the server. The SDK calls the callback when it initializes and again after `refreshAfter` (or `expiresAt` if no refresh time is supplied); a provider authorization failure discards the cached credential so a later request can obtain another. `allowedModels` restricts the model picker; provide a nonempty list or an explicit `models` list so initialization has a model to use. The SDK does not manage the host's login session or the server's revocation policy.

If the provider does not offer a safely scoped client credential, **do not return a long-lived master key to the app**. Keep inference on your server and implement an `AssistantTransport` that sends requests through your authenticated API. An app key delivered to a client is accessible to that client even when the UI hides it.

`identity` is the current host account identifier, or null while signed out. `sessionChanges` should emit when the account changes or signs out. Dispose the assistant and create a new one on an account switch so its transport and cached credential are replaced. Persist conversations in a host-owned `AsystantConversationStore` if they must survive app restarts; scope the store to the same account identity.

## Local tools

`AsystantTool` exposes `definition`, `preview`, `execute`, `requiresConfirmation`, `requiresSelection` and `isAvailable`. `TypedAsystantTool<T>` adds a single domain decoder and typed preview/execution methods. Schema validation rejects unknown fields and wrong scalar types before execution.

A `ToolField` is a scalar (`string`, `integer`, `number`, `boolean`), a list of scalars (`strings`, `numbers`) or a list of objects (`objects`, whose entries have the `fields` you declare). `options` limits a string, or each entry of `strings`, to those values; they travel as the schema's `enum`. A `null` for an optional field counts as absent. When a call is rejected, or a tool returns an `Err`, the failure's `detail` reaches the model with the tool result ("`scene_id` is missing", "`section` does not accept `x`. Valid values: …"), so write a `detail` the model can act on.

`isAvailable` is read before every model call: the model is only offered the tools available at that moment, and a call to one that stopped being available is rejected. Use it to scope tools to what the app shows, such as the current screen.

`requiresConfirmation` is the tool's own answer; the assistant has the last word. `AsystantAI.requiresConfirmation(tool)` is asked on every call, after the preview and before the tool runs, and by default returns the tool's value. Override it when the person can change that answer while the chat is open, such as a setting that approves everything:

For a classified invocation, implement `AsystantActionPolicyProvider` on the tool or override `AsystantAI.actionPolicyFor(tool, arguments)`. The host chooses one of `AsystantSensitivityLevel.none`, `.low`, `.medium`, `.high`, or `.admin` after arguments are validated. The library gives each level its visible name and color: Nulo and Bajo execute without approval; Medio, Alto and Admin require it. `admin` is available for administrator endpoints the host defines. For example, return `const AsystantActionPolicy(level: AsystantSensitivityLevel.high, allowSessionApproval: false)` from `actionPolicy(arguments)` for an action that must be approved every time. The default `allowSessionApproval: true` offers approval for all eligible actions in the current signed-in session only. A required selection is never bypassed. Unclassified tools retain their previous `requiresConfirmation` behavior (true maps to Medio, false to Nulo). The host backend still enforces its own authorization.

`showAsystantSecretPrompt(context, title: ..., fieldNames: ...)` collects transient values on the device after approval. Do not include those fields in model-visible arguments, previews, outcomes or persisted snapshots. It returns `null` if canceled.

Level identifiers and stored names are English; visible labels are localized. Activity shows the level as a compact colored ticket icon beside the action, with the localized name in its tooltip and accessibility label. The context meter is compact in the header action row and opens token details when tapped.

```dart
@override
bool requiresConfirmation(AsystantTool tool) =>
    !settings.approvesAll && tool.requiresConfirmation;
```

The override decides permission only: a tool that `requiresSelection` still waits for the person's choice. A host that draws its own chat passes the same function to `ChatViewModel.configure(confirmation: ...)` (`AsystantConfirmationPolicy`).

`ToolOutcome` carries `modelContent`, the text the model reads, and optionally:

- `summary`: what was done, in one line for the person; it replaces the step's title once the tool completes.
- `data`: a structured result for the host, such as the ids a tool created. It stays on the step (`AssistantStep.data`) and is never sent to the model.
- `card`: a genUI card shown in the chat.
- `endsTurn`: ends the person's turn after this tool. The model is not called again and the remaining calls of that response are answered without running, so the next word belongs to the person. Use it when a tool opens a question only the person can answer, such as a product approval, and say so in `modelContent`.
- `images`: images the model looks at with the result, such as a frame the app just rendered so the model can review its own work. Each is an `AsystantAttachment` with PNG, JPEG, GIF or WebP bytes and its `mimeType` (`AsystantAttachment.fromBytes(bytes: png, filename: 'frame.png')`); non-image files are ignored. They stay in the conversation as the `attachments` of the tool's result message, like the person's own attachments, and every provider sends them in its own format (see [Images](#images)). The person sees them too: the completed step keeps them (`AssistantStep.images`) and the built-in chat shows them as thumbnails under the step, `AsystantTheme.stepImageHeight` high (120 by default).

```dart
@override
Future<Result<ToolOutcome, AssistantFailure>> execute(
  ToolArguments arguments,
  ToolContext context,
) async {
  final png = await canvas.renderPng(); // Host-owned renderer.
  return Ok(
    ToolOutcome(
      modelContent: 'Rendered the current frame; the image is attached.',
      images: [AsystantAttachment.fromBytes(bytes: png, filename: 'frame.png')],
    ),
  );
}
```

Each executed call is an `AssistantStep` with the `toolName`, when it `startedAt`, the `detail` of a failure, the tool's `data` and the `images` it returned. A turn's steps end up in `ChatEntry.activity`, which a conversation store keeps. A store that serializes steps decides whether it keeps their image bytes; one that keeps only a reference (a file path in `data`, say) can load the bytes back into `images` when it reads the conversation, so the thumbnails survive a restart. The built-in chat shows a finished turn's activity under its answer, folded into one line such as "3 steps · completed" (`AsystantStrings.activitySteps`, `activityFinished`, `activityFinishedWithIssues`); the person taps it to see the steps and their images. The turn in progress shows its steps open.

### Progress and cancellation of long tools

A tool that takes a while (a render, an export) reports how far it has come with `ToolContext.reportProgress(fraction, label: ...)`: `fraction` from 0 to 1 (clamped; a non-finite value is ignored) and an optional short `label` for the person, such as "Frame 12 of 48". The running step shows it as `AssistantStep.progress` and `AssistantStep.progressLabel`, and `AssistantStep.showsProgress` is true while it runs with a progress. Report as often as the work advances: the chat shows the first report at once and then at most one every 100 ms, always the latest, so the UI is not rebuilt on every report. Progress never reaches the model, and reports after the call ends or is canceled are ignored. The built-in chat draws it as a thin bar under the step.

`conversation.cancel()` (the chat's Stop button) cancels the turn and reaches the tool that is running: from then on `ToolContext.isCanceled` is true and `checkCanceled()` throws. The SDK cannot interrupt your code, so a long tool checks `isCanceled` as it advances (for example on each progress report) and stops its own work there. The running step ends as `StepPhase.canceled`, and whatever the tool returns afterwards is ignored.

```dart
@override
Future<Result<ToolOutcome, AssistantFailure>> execute(
  ToolArguments arguments,
  ToolContext context,
) async {
  final frames = await renderer.render(
    onFrame: (done, total) {
      if (context.isCanceled) {
        renderer.cancel(); // Host-owned: stop the work.
        return;
      }
      context.reportProgress(done / total, label: 'Frame $done of $total');
    },
  );
  return Ok(ToolOutcome(modelContent: 'Rendered ${frames.length} frames.'));
}
```

A preview must be read-only. Mutating actions require confirmation by default. The model cannot approve its own action. Check `ToolContext.isCanceled` or `checkCanceled()` immediately before an asynchronous write, and use its `idempotencyKey` in your own repository. Existing product authorization is still mandatory; a model-requested action is not an authorization grant.

### Turn limits

The SDK bounds each user turn to 8 inference rounds and 16 tool calls per response by default. `init(turnLimits: ...)` changes them, the same way for every provider, because the chat enforces them, not the transport:

```dart
assistant.init(
  provider: provider,
  turnLimits: const AsystantTurnLimits(maxRounds: 20, maxCallsPerResponse: 8),
);
```

Both are positive integers with a ceiling, so a host mistake cannot leave a turn calling the model without end: `maxRounds` from 1 to `AsystantTurnLimits.maxRoundsCeiling` (64), `maxCallsPerResponse` from 1 to `AsystantTurnLimits.maxCallsCeiling` (16). The call ceiling is the built-in transports' own: `OpenRouterProvider` and `ClaudeCodeProvider` refuse a response with more than 16 calls as a protocol failure, so a higher value could not take effect. `init` throws a `RangeError` for a value outside its range, before storing anything.

When a turn reaches a limit:

- **Rounds.** A round that answers without tool calls ends the turn normally. When the last allowed round still proposes calls, they run as usual (permission included) and their results are added to the conversation, but the model is not asked again. The turn ends with a `FailureCode.limit` failure: the turn's steps stay visible in the chat and the failure notice reads "This operation reached its limit. You can start a new request." The model receives nothing more in that turn; on the person's next message it sees the whole history, those tool results included, with no final answer after them.
- **Calls per response.** A response with more calls than `maxCallsPerResponse` is refused as a `FailureCode.protocol` failure: none of its calls run, the response is not added to the conversation, so the model never sees it, and the chat shows the generic failure notice.

The SDK does not automatically retry uncertain writes or reverse effects already committed. Tool result text returns to the model; optional cards remain in chronological order in the chat.

## Local knowledge (RAG)

The app supplies documents about its own domain (guides, FAQs, policies, catalog entries), and the model searches them with a built-in tool before answering. Everything runs inside the app: no service, no embeddings model, no extra dependency, and it works the same with every provider.

`AsystantKnowledge` is a local index of `KnowledgeDocument`s. Each has an `id` chosen by the app, a `title`, the searchable `text`, and optionally a `collection` (the kind of document, used to narrow a search), `tags` and `metadata` (simple string values the app wants back, such as a route; not searched and not sent to the model). `put` adds a document or replaces the one with the same id, `putAll` adds several, `remove` and `clear` delete.

```dart
final knowledge = AsystantKnowledge(
  documents: [
    for (final guide in await repository.careGuides()) // Host-owned data.
      KnowledgeDocument(
        id: 'guide-${guide.id}',
        title: guide.title,
        text: guide.body,
        collection: 'guides',
        tags: guide.tags,
        metadata: {'route': '/guides/${guide.id}'},
      ),
  ],
);

assistant.init(
  provider: provider,
  builtInTools: [KnowledgeSearchTool(knowledge: knowledge)],
);
```

The model calls `search_knowledge` with a `query`, an optional `collection` (the index's collections are offered as its accepted values) and an optional `limit` (5 by default, at most 10), and reads compact JSON with the passage that matched, not the whole document:

```json
{"query":"riego orquídeas","results":[{"id":"guide-12","title":"Cuidado de la orquídea","collection":"guides","score":2.41,"snippet":"…Riega las orquídeas una vez por semana, por la mañana…"}]}
```

The tool only reads, so it runs without asking for permission; the step shows the query. The ids found are kept in the step's `data['ids']` for the host. `KnowledgeSearchTool` takes `name` (for example to register two indexes as two tools), `description`, `defaultLimit` and `maxLimit`. Documents added or removed later are searched from the next call on; the collections offered are read before each model call.

**Ranking.** `AsystantKnowledge` ranks with BM25, the lexical scoring of classic search engines, over the title (weighted double), the tags and the text. Text is normalized for Spanish and English: lower case, accents folded (`orquídea` = `orquidea`, `ñ` = `n`), common words of both languages dropped, and a light stemmer that joins singular and plural, masculine and feminine (`orquídeas` = `orquídea`, `luces` = `luz`, `cities` = `city`). A query word of four letters or more also matches the longer words it starts (`jardín` finds `jardinería`, `water` finds `watering`). `collection` and `tags` filter before ranking; a document must carry every requested tag. Each hit's `snippet` is the passage of about 320 characters (`snippetLength`) that covers the most query words, cut at a sentence or word boundary with `…`. `rank(query)` is the synchronous form of `search(query)`, for the host's own screens.

**Why lexical, not embeddings.** For this first version the index needs no model, no network and no dependency, runs on mobile, web and desktop, and is deterministic: the same documents and query always give the same order, so it can be tested. It finds the words of the question, not their synonyms: a question about "watering" does not find a document that only says "irrigation", and the model is told to try other words when nothing matches. It searches a few thousand documents in a few milliseconds; building the index costs roughly half a second per million words, so on native platforms build a large one away from the UI isolate, for example `await Isolate.run(() => AsystantKnowledge.fromJson(saved))`.

**Persistence.** `knowledge.toJson()` returns the documents, with a format `version`, as JSON-compatible data, and `AsystantKnowledge.fromJson(json)` rebuilds the index from them. The SDK does not decide where it is stored: a file, a local database or your backend.

**A different retriever.** `KnowledgeSearchTool` depends on `KnowledgeRetriever`, not on the lexical index: a class with `search(KnowledgeQuery)`, returning `Future<Result<List<KnowledgeHit>, AssistantFailure>>`, and optionally `collections`. A semantic or hybrid retriever (embeddings, a vector store, a search service) implements it and replaces `AsystantKnowledge` where it is passed, with no other change in the app or the tool. Return an `Err` only when the retriever cannot answer; its `detail` reaches the model.

Search results come from documents, and the baseline safety prompt already tells the model to treat tool output as untrusted data; index only content the person using the app is allowed to read.

## Business APIs

`asystant_core` describes the administrative API of a business as a typed contract, and `asystant_ai` gives the assistant the tools to register it, sign in and run its operations. Credentials never enter the contract, the conversation or the model.

### Contract

A `BusinessContract` has an `id`, a `name`, optional `dev` and `prod` `BusinessEndpoint`s and its `BusinessOperation`s. An operation is `METHOD path` with typed `BusinessField`s: a `BusinessFieldKind` (`string`, `integer`, `number`, `boolean`, `object` with typed `properties`, `list` with a typed `item`, or `secret`) and a `BusinessFieldLocation` (`path`, `query`, `body`, `header`), plus `options`, `minimum` and `maximum`. Endpoints and operations may add public `headers` and `privateHeaders`, whose values live in the device vault.

`BusinessContract.parse(json)` reads untrusted JSON into a `Result`, and `contract.validateContract()` checks it before it is saved: identifiers, addresses (PROD needs https), headers, the sign-in flow, profiles, operation routes and every field. `operation.validateArguments(arguments)` checks one call.

### Sign-in as data

An endpoint's `auth` is a `BusinessAuthFlow`: `scheme` (`bearer` or `apiKey` with `apiKeyHeader`) says how the saved credential is sent; `steps` say how it is obtained. Each `BusinessAuthStep` is a `POST` with a `kind` (`request`, `verify`, `password`, `totp`, `refresh`), a `path`, the `BusinessAuthInput`s the person types (`email`, `password`, `code`, `totp` or `text`, each sent as its `field`), and `carry`, values taken from the previous answer such as a second-factor challenge. The flow also holds the fixed `parameters` every step sends (editable in the first form), `requiredParameters`, sign-in `headers`, a separate `baseUrl`, the `tokenPath` of the answer, the refresh token and session id members, and an optional required role. A flow without steps uses an API key or Bearer token saved directly.

Named constructors build the usual flows: `bearer()`, `apiKey(header:)`, `emailCode`, `emailCodeTotp`, `emailPassword`, `emailPasswordTotp`, `aulaMasOperator` and `sstOperator`; `copyWith` and `withRefresh(path)` finish them. LoginFlow, for example:

```dart
final loginFlow = BusinessAuthFlow.emailCode(
  requestPath: '/v1/public/request-otp-login',
  verifyPath: '/v1/public/login-with-otp',
).copyWith(
  baseUrl: 'https://api.loginflow.example',
  parameters: {'application_id': 'app-1', 'company_id': 'company-1'},
  requiredParameters: ['application_id', 'company_id'],
  tokenPath: 'jwt',
  reusesTokenForRefresh: true,
).withRefresh('/v1/public/refresh-token');
```

In JSON the same flow is the `auth` object of the endpoint (`scheme`, `parameters`, `required_parameters`, `steps: [{kind, path, inputs: [{name, kind, field}], carry}]`, `token_path`, ...). Contracts saved in the first format, a flat `auth_kind` (`bearer`, `apiKey`, `emailCode`, `emailCodeTotp`, `emailPassword`, `emailPasswordTotp`, `aulaMasOperator`, `sstOperator`) with `request_path`, `verify_path`, `totp_path`, `login_path`, `refresh_path`, `token_field`, `auth_parameters` and the other flat members, are still read: `BusinessEndpoint.fromJson` hands them to `BusinessAuthFlow.fromLegacyJson`, and `toJson` writes the current format.

`BusinessSignIn.signIn` runs the steps in order. Before each one it calls a `BusinessSignInPrompter` with a `BusinessSignInRequest`: the inputs not typed yet, the parameters (first form only) and a `BusinessTotpEnrollment` when the API enrolls a new authenticator. An input with the same name in two steps is typed once. A 4xx answer that carries every value the next step needs is a challenge, not a rejection. The token, refresh token, session id and last email go to the credential store; `BusinessSignInOutcome` returns the parameters the person confirmed. `refresh` renews a session once at a time per scope.

### Profiles, stores and execution

An endpoint can declare several `BusinessCredentialProfile`s, such as `admin` and `guest`; each signs in separately. A `BusinessCredentialScope` (account, business, environment, profile) keys every stored value. Without declared profiles an environment has one default profile.

The host implements three interfaces: `BusinessHttp` (`BusinessHttpClient` is the default over `package:http`: JSON bodies, no redirects, a timeout), `BusinessCredentialStore` (credential, session values, last email and private headers per scope; `asystant_ai` ships `SecureCredentialStore` over `flutter_secure_storage`) and `BusinessContractStore` (list and save the contracts of an account, locally or synced with a server). Every method answers a `Result` with a `BusinessFailure`.

`BusinessExecutor.execute` validates the arguments, builds the request (path, query, body, headers, the credential per scheme, private headers and an `Idempotency-Key` for writes) and redacts every secret from the answer. On 401 it renews the session once and retries; when renewal is impossible or rejected it clears the session and answers `BusinessFailureCode.sessionExpired`. `contract.sessionResetsFrom(previous)` says which sessions a new version of a contract invalidates: a changed address or sign-in clears them, a header change does not.

### Tools

`BusinessToolkit` wires it together for an assistant:

```dart
class ShopAssistant extends AsystantAI {
  ShopAssistant(this.session);

  final Session session;

  late final business = BusinessToolkit(
    contractStore: MyContractStore(), // Host-owned.
    credentialStore: const SecureCredentialStore(),
    documentStore: JsonBusinessDocumentStore(
      readValue: preferences.read, // Host-owned key/value store.
      writeValue: preferences.write,
      removeValue: preferences.remove,
    ),
    accountId: () => session.userId,
    strings: AsystantStrings.spanishLabels,
  );

  @override
  List<AsystantTool> get tools => [...business.tools];

  @override
  Future<List<AsystantSystemPrompt>> contextPrompts() async => [
    await business.contextPrompt(),
  ];
}
```

The tools, named by `BusinessToolNames`:

- `register_business` (`RegisterBusinessTool`): registers a contract the model writes, for example from an attached `.md`. A contract with a credential in it is rejected.
- `update_business` (`UpdateBusinessTool`): corrects the sign-in, addresses, headers, profiles or operations in place; sessions survive unless the address or sign-in changed. `builtInOperations` protects operations that ship with the app.
- `connect_business` (`ConnectBusinessTool`): runs the sign-in flow with secure forms (email, parameters pre-filled, password, codes, missing private headers). `onTotpEnrollment` lets the host show a QR; without it the manual key appears in the code form.
- `operate_business` (`OperateBusinessTool`): runs an operation with the saved session and gives the redacted answer to the model. It never opens a form: a missing session, private header or secret field fails naming the tool to call first.
- `configure_business_environment` (`ConfigureBusinessEnvironmentTool`): saves an address and an API key or Bearer token given as a private chat value.
- `configure_business_private_header` (`ConfigureBusinessPrivateHeaderTool`): saves a declared private header from a private value or a secure form.
- `enter_business_secrets` (`EnterBusinessSecretsTool`): asks for an operation's secret fields and holds them for its next call, which uses them once.
- `read_business_docs` (`ReadBusinessDocsTool`): reads the source document of a business, the sections that match `query` (or the beginning), cut to 8000 characters, with every heading.

Register and update accept the source document of the contract: `document_attachment_id` for a text file attached to the chat (the endpoints `.md`) or `document` as text. It is kept as a `BusinessDocument` in `toolkit.documentStore`, one per business, replaced by a newer one; a document with a credential in it is refused. `BusinessDocumentStore` is in memory by default; `JsonBusinessDocumentStore` persists it through the same key/value callbacks as `AsystantJsonConversationStore`. In pure Dart, `document.matchingSections(query)` splits it at its Markdown headings and ranks the sections with `AsystantKnowledge`. The context prompt says which businesses have documentation.

The chat withholds from the model the outcome of any tool that used private input or a secret reference. That is why secrets are always entered by a tool other than `operate_business`: the operation's answer stays visible. `BusinessApprovalPolicy` asks approval only for destructive operations (`DELETE` by default, high sensitivity, every time); every other business tool runs directly. `BusinessContextPrompt` (`toolkit.contextPrompt()`) lists the rules, every registered operation and, per environment and profile, how it signs in and whether a session is saved, without any credential or parameter value. Card titles, form labels and step summaries come from `AsystantStrings`; what the model reads stays English.

## Embedding and customization

`AsystantButton` opens the chat in a bottom sheet (`AsystantPhoneSheet`) on phones and in a side panel (`AsystantPanel`) on tablets and desktops. `AsystantChat` is a bounded section without its own app router or Scaffold; use it in drawers, panels and full screens. Colors follow the host theme's `ColorScheme`: mainly `surface`, `surfaceContainerLow`, `surfaceContainerHigh` and `surfaceContainerHighest` (cards, composer), `primary` (actions, accents), `primaryContainer` and `onPrimaryContainer` (the person's messages), `onSurface`, `onSurfaceVariant` (secondary text), `outlineVariant` (borders) and `error`. A host whose app theme only sets the basic roles can wrap the chat in a `Theme` that fills these from its own palette. `AsystantTheme` controls dimensions. English labels are the default; use `AsystantStrings(spanish: true)` or a host subclass for another language.

GenUI supports summary, entity, selection, permission and result cards. Selections use stable option strings that tools can map to host domain identifiers. Tool steps show preparing, permission, running, completed, declined, canceled and failed states.

## Deferred startup

`init()` only stores configuration. It does not evaluate application tool getters,
request a credential, or contact the provider. `AsystantChat` starts setup after its first
frame, only when mounted; a launcher button alone does not initialize the assistant.
Do not await assistant readiness before `runApp()` or host authentication.
For a custom chat UI, call `ensureInitialized()` when that UI opens. Concurrent calls
share initialization. Draw it from `assistant.conversation`, a
`ReactiveNotifierViewModel<ChatViewModel, ChatState>`: `ChatState` holds the entries,
the steps of the running turn, the streamed text, the pending permission and the
failure, and `ChatViewModel` exposes `send`, `cancel`, `approve`,
`openConversation`, `newConversation`, `deleteConversation` and
`reloadConversations`. Network failures remain inside the assistant UI and do not
prevent the host app from starting.

Network I/O uses asynchronous Dart APIs. An isolate is unnecessary for this work and
would not support application tools holding UI or service references. Keep tool
registration cheap; move any genuinely CPU-intensive application computation to an
isolate inside that tool. Startup has no dependency on the assistant's network latency;
this is not a claim of literally zero CPU cost.

Migration from 0.1.0: remove `await` before `init()`. Only headless clients and tests
that immediately send messages should explicitly await `ensureInitialized()`.

## Closing the chat while work continues

Own the `AsystantAI` instance in the authenticated application session, outside
the sheet, drawer or route that displays it. Closing `AsystantChat` only removes
the view. Initialization, pending HTTP requests, local asynchronous tools and
responses continue in the same conversation. Reopen with the same instance to
show its current steps, messages, cards and any pending approval. Reopening does
not resend a message or repeat a tool call.

Do not call `assistant.dispose()` from the chat panel's `dispose()` or close
callback. Use `assistant.conversation.notifier.cancel()` for an explicit Stop
action, and dispose the assistant when its owning login session ends. Changing
the authenticated identity invalidates pending operations and clears old results.
A permission requested while the panel is hidden waits for the user to reopen
and approve; hiding the chat never grants permission.

Provider text is accumulated and published to reactive state in 32 ms batches.
The final response does not wait for that timer. Execution is independent of
mounted widgets and animation frames, so a hidden panel does not stall the tool
loop. Network I/O is asynchronous; it does not need an isolate. A custom tool
that performs substantial synchronous CPU work must offload that calculation
using a platform-appropriate worker (for example `compute` on native Flutter),
passing serializable data and keeping UI/service references in the host isolate.
`compute` does not create a separate worker on Flutter web.

This lifetime applies while the application process can run. It does not promise
execution after a mobile OS suspends/terminates the app, a browser tab is closed,
or the process exits. That requires a separate durable background-job design.

## System prompts and safety

Override the getter for application personality, business terminology and tool
usage guidance. Add session-scoped, non-secret context during configuration:

```dart
class WorkspaceAssistant extends AsystantAI {
  WorkspaceAssistant() : super(name: 'Workspace assistant');

  @override
  List<AsystantTool> get tools => [ReadWorkspaceTool()];

  @override
  List<AsystantSystemPrompt> get systemPrompts => const [
    AsystantSystemPrompt(
      id: 'workspace.personality',
      content: 'Be concise and helpful. Explain proposed changes before asking '
          'for approval. Use tools to confirm current workspace settings.',
    ),
  ];
}

assistant.init(
  provider: provider,
  additionalSystemPrompts: const [
    AsystantSystemPrompt(id: 'workspace.context', content: 'Reply in English.'),
  ],
  builtInTools: const [ChartPresentationTool()],
);
```

`AsystantPromptPolicy.security` is always first. Duplicate IDs, empty instructions,
and replacement of the reserved security ID are rejected. Up to 15 application
prompts may supplement the baseline. Every provider's transport composes the same
baseline again in `initialize`, so it also applies when a transport is used without
the Flutter chat.
The baseline treats retrieved content and tool output as untrusted, prohibits
claiming approval or successful writes without evidence, and instructs the model
not to disclose secrets. It is guidance, not a guarantee against prompt injection.
Never put secrets into prompts; authorization, validation and confirmation remain
mandatory application/server responsibilities.

`contextPrompts()` returns what the app knows right now, such as the person's saved
profile. The chat reads it before every model call and sends it after the configured
prompts, for that request only. Up to `AsystantPromptPolicy.maxContext` (8) entries
are accepted, with the same identity rules. Keep it short and write it as data about
the person rather than as instructions.

## Charts in genUI

Application tools can return an `AssistantCard` containing an `AssistantChart`.
The same component works inside summary, entity, permission and result cards.
Bar and line presentations preserve negative values and include labeled values
for screen readers. Each series is limited to 24 finite measurements; the host
supplies its source, period, unit and completeness. Invalid charts are not rendered.

```dart
const card = AssistantCard(
  title: 'Weekly activity',
  body: '146 completed appointments.',
  chart: AssistantChart(
    title: 'Weekly activity',
    unit: 'appointments',
    source: 'Demo data · Sep 21–25, 2026 · Complete sample',
    points: [
      ChartPoint(label: 'Customer service', value: 72),
      ChartPoint(label: 'Collections', value: 46),
      ChartPoint(label: 'Information', value: 28),
    ],
  ),
);
```

For model-arranged charts, explicitly enable `ChartPresentationTool()` or
`ChartPresentationTool(kind: AssistantChartKind.line)`. This optional tool only
presents data; it cannot fetch private information or change application records.
For authoritative reporting, build the card directly in the local data tool.

## Diagrams in messages

A ```` ```mermaid ```` block in a completed message or card body whose source is a
flowchart (`flowchart` or `graph`, any direction) is drawn as a diagram: a card sized
to it inside the message, and a full view with pan, zoom and its source on a tap. It
is parsed, laid out and painted on the device, so diagrams carrying private project
details never reach a web view or a rendering service. Other Mermaid diagram types,
and flowcharts using syntax outside the supported subset, stay code blocks. Use
`AsystantMermaidDiagram(source: …)` to draw one anywhere, and `AsystantMarkdownText`
to render agent Markdown outside the chat with the same diagrams, links and image
rules:

```dart
AsystantMarkdownText(
  text: decision.markdown,
  selectable: true,
  onOpenLink: (uri) async => router.openIfInternal(uri),
  strings: AsystantStrings.spanishLabels,
);
```

The tallest a diagram gets in a message is `AsystantTheme.diagramMaxHeight`.

## Links, selection and copying

Completed messages and card bodies render Markdown, including named links such as
`[Open settings](https://app.example.com/settings)` and bare HTTP(S) URLs. Links
open only after a user taps them. The default opens the external browser; failures
appear inside the assistant in the selected language. Image markup renders its
alternative text without loading remote images or local files.

The conversation is one selectable area, including streamed text, card titles,
chart labels and results. Use mouse selection and Ctrl+C / Cmd+C on desktop, or
long press and Copy on mobile. Selecting text never follows its links, and active
selection pauses automatic scrolling. Streaming uses plain text until completion,
so partial tokens do not repeatedly parse Markdown.

`AsystantChat` and `AsystantButton` both accept a typed `onOpenLink` callback when
the host needs to route a link within its application:

```dart
AsystantChat(
  assistant: assistant,
  onOpenLink: (uri) async {
    if (uri.host == 'app.example.com' && uri.path == '/settings') {
      await Navigator.of(context).pushNamed('/settings');
      return true;
    }
    return false;
  },
);
```

Return `true` when the host handled navigation, or `false` to show link feedback.
HTTP(S) validation applies before custom callbacks too: credentials in URLs and
schemes such as `javascript`, `data` and `file` are rejected. A standalone
`GenUiCard` can be wrapped in Flutter's `SelectionArea` when used outside the chat.

### Host content: header, cards with actions, conversations

`identityIcon` replaces the header's default sparkle with a host widget.
`welcomeContent` replaces the welcome view only when the conversation is empty;
the built-in activity timeline, messages, composer and approvals remain in place.

These `AsystantChat` parameters put the host's own state inside the chat, for an assistant embedded in a larger workflow. None of them is stored with the conversation or sent to the model.

- `headerContent`: a widget under the header, such as what the assistant is working on right now (the open document, the current stage). It stays in place while the conversation scrolls.
- `hostCards`: cards pinned after the conversation, each an `AsystantHostCard` with an `AssistantCard` (title, Markdown body, optional chart) and its `actions`, `AsystantCardAction`s with a `label`, an `onPressed` callback (null draws the button disabled) and `isPrimary`. Use them for a decision the host's workflow waits for, or for a notice. The card reflects host state: rebuild the chat with the cards that apply now, so a decision taken elsewhere in the app removes its card here too. A card with an enabled action stands out like a permission request and brings the end of the conversation into view.
- `managesConversations`: `false` hides the conversation list, New conversation and Delete, and the "start a new one" actions of the context notices. Use it when the host keeps one conversation per context (for example one per open document) and switches it itself with `openConversation`.

  A host can also keep **several conversations per context** and leave `managesConversations` on: its `AsystantConversationStore` answers `list` for the context open now, and when the context changes the host calls `assistant.conversation.notifier.reloadConversations()`, which keeps the conversation on screen in the store and replaces the list with exactly what the store answers, newest first. Then it opens one with `openConversation` (the most recent, for example) or starts one with `newConversation`. A write for a conversation must still reach the context it belongs to, even if the host already switched: resolve it from the conversation id, not from the context open now.

```dart
AsystantChat(
  assistant: assistant,
  managesConversations: false,
  headerContent: Text('Chapter 3 · draft'),
  hostCards: [
    if (review.isPending) // Host-owned state.
      AsystantHostCard(
        card: AssistantCard(title: 'Publish chapter 3', body: review.summary, kind: .permission),
        actions: [
          AsystantCardAction(label: 'Publish', onPressed: review.publish, isPrimary: true),
          AsystantCardAction(label: 'Keep editing', onPressed: review.reject),
        ],
      ),
  ],
)
```

`review` is host-owned. A host card is not a tool permission: the SDK's own confirmation card keeps asking for tools that require it, and a host card never approves a tool call.

Failures read as `AsystantStrings.failureMessage(failure)`, by default the wording of `failure(code)`. A subclass can add what the provider reported (`AssistantFailure.detail`, such as which program is missing) or say where the person fixes it in the host app.

### Host-owned card content

Pass `cardContentBuilder` to `AsystantChat` or `AsystantButton` to add domain UI
beneath a completed local tool card. Return `null` for cards your host does not
recognize. The standard title, body and chart stay visible. Pending permission
cards never invoke this builder, so custom content cannot replace consent.

```dart
AsystantChat(
  assistant: assistant,
  cardContentBuilder: (context, card) => switch (card) {
    PublicQrCard() => PublicQrPreview(card: card),
    _ => null,
  },
)
```

`PublicQrCard` and `PublicQrPreview` in this example are host-defined types.
A local tool may return an `AssistantCard` subclass with a typed public URL or
artifact identifier. Keep builds free of side effects and start downloads only
from explicit button callbacks. Generate QR images locally; do not interpret
model text as arbitrary widgets, file paths or trusted remote images. Override
`toJson`, `copyWith` and the host decoder when extending card data. The SDK's
base `AssistantCard.fromJson` does not restore host subclasses automatically.
### Localizing the library UI

English is the default even when the device locale is not English. Every built-in chat label, status, failure, conversation action and provider-settings label is supplied through `AsystantStrings`. The host can support any language: subclass `AsystantStrings`, override getters and methods such as `newConversation`, `deleteConversation`, `providerSettingsTitle`, `phase`, and `failureMessage`, and register the instances in `AsystantStrings.forLocale(locale, translations: {'fr': frenchStrings, 'pt-BR': brazilianPortugueseStrings})`. Language and region tags are matched case-insensitively; region-specific entries take priority. An unknown locale falls back to English. The built-in Spanish set is selected for `es` only if the host did not register its own Spanish strings. Pass the selected instance through `strings:` on `AsystantChat`, `AsystantButton`, `AsystantPanel`, or `AsystantPhoneSheet`, and rebuild when the locale changes. Any labels not overridden by the host retain their English defaults. The provider settings sheet receives that same instance. `AsystantDashboardWelcome` takes its own optional copy parameters; host-defined tool and model text remains the host's responsibility.

### Local provider settings

`AsystantAI.init(providerSettings: AsystantProviderSettings(namespace: ...))`
enables the library-owned **AI settings** entry in the chat's dropdown. The
existing `provider` remains the default when the selection is `backend`.
The namespace must identify the app and signed-in account, for example
`app-id:tenant-id:user-id`; do not share it between accounts. This option
requires `provider:`, because a custom `transport:` cannot be reconstructed
after switching away and back.

`AsystantProviderSelection` stores provider kind, HTTPS base URL, display name
and primary model ID (also selectable for the backend). `AsystantProviderSettings` stores the API key separately
with `flutter_secure_storage`; a blank key field keeps the saved value. The
sheet never repopulates the key field and offers deletion of a local key. **Test connection** checks the key without saving a newly entered value; a compatible endpoint that lacks `GET /models` may not support that check, so saving remains available. The backend option does not require a
local key. Save is disabled while a turn runs, and switching provider creates
a new transport. Conversation history stays scoped to the selected provider
identity and the host's configured conversation store.

The built-in local choices are OpenAI/GPT, OpenRouter, Gemini's OpenAI-compatible endpoint,
Claude API's OpenAI-compatible endpoint, and a user-supplied HTTPS
OpenAI-compatible Chat Completions base URL. Enter the exact model ID permitted
by the API key. Custom providers must support streamed Chat Completions and
OpenAI-style tool calls to run local tools. This is an OpenAI-compatible API
contract; OpenAPI is the separate format for describing REST endpoints.

Claude Code CLI login is supported separately by `ClaudeCodeProvider` on
desktop, and does not turn into a mobile API key. Claude API keys are billed
separately and use the compatibility endpoint. That compatibility layer has
limitations for advanced Claude features; use the native API in a future
provider if those features are required.

The host can hide provider settings completely with
`AsystantProviderSettings(showInChatMenu: false, namespace: ...)`, or omit
`providerSettings` from `init`. Pass `availableKinds` to expose only selected
values of `AsystantProviderKind`; a previously saved kind that is no longer
allowed falls back to the first allowed kind. For a backend-only client app,
`availableKinds: [AsystantProviderKind.backend]` leaves no local key choices.
The settings sheet uses the `AsystantStrings` supplied to the chat.

### Composer controls and attachment rules

`AsystantChat`, `AsystantButton`, `AsystantPanel` and `AsystantPhoneSheet`
accept independent `attachmentActionPlacement` and
`privateValueActionPlacement` values: `inside`, `outside` or `hidden`.
`enablePrivateValueAttachment` still defaults to false; the attachment policy's
`enabled: false` also hides its button. For example:

```dart
AsystantChat(
  assistant: assistant,
  enablePrivateValueAttachment: true,
  attachmentActionPlacement: AsystantComposerActionPlacement.outside,
  privateValueActionPlacement: AsystantComposerActionPlacement.inside,
  attachments: AsystantAttachmentPolicy(
    allowedExtensions: const ['md', 'pdf'],
    maxFileBytes: 5 * 1024 * 1024,
    maxFiles: 3,
    blockedFilenamePatterns: [RegExp(r'\.env$', caseSensitive: false)],
    blockedTextPatterns: [RegExp('private credential', caseSensitive: false)],
  ),
)
```

The policy also accepts `allowedMimeTypes` (including `image/*`) and
`allowedFilenamePatterns`. Extension, MIME and allow-regex constraints all
apply when configured; any deny-regex rejects the file. Text rules run only
for attachments recognized as text, after the size limit. The system picker
filters extensions before reading, and the view model validates every file
again, including custom pickers and programmatic attachments. For an `other`
private value, the sheet asks for the name shown to the model alongside an
opaque reference; its actual value remains in the local vault.
