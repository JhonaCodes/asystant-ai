# asystant_ai

An embeddable Flutter assistant with local application tools, explicit permissions, genUI cards and reactive_notifier state. Use the same chat in a section, bottom sheet, end drawer or full screen on mobile, web and desktop.

## Install

```sh
flutter pub add asystant_ai
```

## Create your assistant

```dart
import 'package:asystant_ai/asystant_ai.dart';

class WorkspaceAssistant extends AsystantAI {
  WorkspaceAssistant() : super(name: 'Workspace assistant');

  @override
  List<AsystantTool> get tools => const [];

  @override
  List<AsystantSystemPrompt> get systemPrompts => const [
    AsystantSystemPrompt(
      id: 'workspace',
      content: 'Help inside this workspace. Use local tools for actions.',
    ),
  ];
}
```

Then call `assistant.init` once with an `AssistantTransport`. `init` only stores the configuration; the chat connects when it is first shown. Two transports are included:

- `OpenRouterTransport` calls OpenRouter directly with a short-lived, budget-limited key. Its `credentials` function asks your backend for the key; your backend gets it from [asystant-api](https://github.com/JhonaCodes/asystant-api) (`POST /v1/managed/credentials`), and `OpenRouterCredential.fromManagedJson` reads the response. Never compile a provider key into a release build.
- `ClaudeCliTransport` runs the Claude Code CLI installed on a desktop machine with the user's own subscription, without an API key or backend.

```dart
assistant.init(
  transport: OpenRouterTransport(
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

`fetchAiCredential` (an `OpenRouterCredentialSource`, returning `Result<OpenRouterCredential, AssistantFailure>`) and `session` are supplied by your app. `models` are the choices shown next to the send button; the first one permitted is the default. Pass `models: const []` to offer exactly the models the credential allows. Add optional factory tools through `builtInTools`. See the [integration guide](https://github.com/JhonaCodes/asystant-ai/blob/main/docs/public-api.md#credentials-and-sign-in) for the credential flow.

## Embed the chat

```dart
AsystantButton(assistant: assistant); // A sheet on phones, a side panel on tablets and desktops.

AsystantChat(
  assistant: assistant,
  strings: const AsystantStrings(spanish: false),
); // Mount inside a bounded section, drawer or full-screen Scaffold.
```

The host owns the assistant instance: closing the panel preserves the conversation. Call `assistant.dispose()` when its owner ends. When the transport reports a different identity, pending permissions are invalidated, the conversation is cleared and the chat offers to connect again. When another user signs in, dispose the assistant and create a new one.

## Tools and permissions

Implement `AsystantTool` or `TypedAsystantTool<T>`. Return a `ToolDefinition`, a read-only preview and an execution result. Tools execute inside the host app, never on a server. Confirmation is required by default; read-only tools can explicitly opt out. Use `requiresSelection` for user choices and `isAvailable` to control registration.

`ToolContext` exposes cancellation, selected values and an idempotency key. Your repository must still enforce authorization and protect asynchronous writes against duplicate effects. The SDK does not claim to reverse completed actions.

Cards support summary, entity, selection, permission and result presentations. The chat shows ordered tool steps, progress and error icons, and an action that changes from Send to Stop. Theme colors follow the host; use `AsystantTheme` for metrics and subclass `AsystantStrings` for custom wording or languages. English and Spanish are included.

## Backend and models

The package does not include a hosted API, provider credentials or inference credits. For `OpenRouterTransport`, you can deploy [asystant-api](https://github.com/JhonaCodes/asystant-api), a self-hosted service that issues OpenRouter keys with per-tenant and per-user budgets to your backend. It never proxies inference: the app talks to OpenRouter directly. See its [OpenAPI contract](https://github.com/JhonaCodes/asystant-api/blob/main/openapi.yaml) and [managed keys guide](https://github.com/JhonaCodes/asystant-api/blob/main/docs/managed-keys.md), and this repository's [security policy](https://github.com/JhonaCodes/asystant-ai/blob/main/SECURITY.md).

Implement `AssistantTransport` to reach another provider or your own service. Provider availability and usage terms must be checked before enabling a model.

## Example

[example/lib/main.dart](example/lib/main.dart) runs without credentials using an explicitly simulated assistant response and a real local read-only tool. The repository also includes a complete [host app](https://github.com/JhonaCodes/asystant-ai/tree/main/examples/host_app), Botánica, whose assistant uses `OpenRouterTransport`, local tools, context prompts and host-owned card content.

## License

MIT. See [LICENSE](LICENSE).

### Deferred startup

`init()` only stores configuration. It does not evaluate application tool getters,
request a credential, or contact the provider. `AsystantChat` starts setup after its first
frame, only when mounted; a launcher button alone does not initialize the assistant.
Do not await assistant readiness before `runApp()` or host authentication.
For a custom chat UI, call `ensureInitialized()` when that UI opens. Concurrent calls
share initialization. Network failures remain inside the assistant UI and do not
prevent the host app from starting.

Network I/O uses asynchronous Dart APIs. An isolate is unnecessary for this work and
would not support application tools holding UI or service references. Keep tool
registration cheap; move any genuinely CPU-intensive application computation to an
isolate inside that tool. Startup has no dependency on the assistant's network latency;
this is not a claim of literally zero CPU cost.

Migration from 0.1.0: remove `await` before `init()`. Only headless clients and tests
that immediately send messages should explicitly await `ensureInitialized()`.

## Reports and prompt customization

Application personality is supplied through `AsystantAI.systemPrompts`; scoped
context can be added with `additionalSystemPrompts` during `init()`, and what the app
knows right now through `contextPrompts()`. Both transports place the SDK's baseline
safety guidance first. See the
[integration guide](https://github.com/JhonaCodes/asystant-ai/blob/main/docs/public-api.md).

Cards now support typed bar and line charts, with accessible labels, units and
source notes. These are English Flutter golden renders using example data:

![Mobile report with bars and trend](https://raw.githubusercontent.com/JhonaCodes/asystant-ai/main/packages/asystant_ai/test/goldens/report_390.png)

[Desktop golden](https://raw.githubusercontent.com/JhonaCodes/asystant-ai/main/packages/asystant_ai/test/goldens/report_900.png)

See [model experience and verification](https://github.com/JhonaCodes/asystant-ai/blob/main/docs/model-experience.md)
for owner-reported GPT-OSS 20B/120B results and the boundary of automated testing.

## Links and copying

Completed messages and card bodies support named Markdown links and bare HTTP(S)
URLs. Tap a link to open it, drag to select and copy on desktop, or long press and
choose Copy on mobile. Card and chart text participates in the same selection;
automatic scrolling pauses while text is selected. Streamed text stays lightweight
until the message completes.

Use `onOpenLink` on `AsystantChat` or `AsystantButton` to provide a host navigation
callback returning `FutureOr<bool>`. Return `true` when handled or `false` for
localized feedback inside the chat. Both default and custom navigation accept
credential-free HTTP(S) URLs only. Model-supplied images render alternative text
without automatically loading external resources. See the
[link integration guide](https://github.com/JhonaCodes/asystant-ai/blob/main/docs/public-api.md#links-selection-and-copying).
