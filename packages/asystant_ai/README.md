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

After your host services and login are ready, call `assistant.init` with a `GatewayTransport`. Its `SessionSource` obtains signed tickets from your backend; provider API keys never belong in Flutter. Pass `models: []` to accept the server-assigned model and add optional factory tools through `builtInTools`.

```dart
await assistant.init(
  transport: GatewayTransport(
    baseUri: gatewayUri,
    sessionSource: hostSession,
  ),
  models: [],
  builtInTools: const [
    PresentationTool(kind: AssistantCardKind.summary),
    PresentationTool(kind: AssistantCardKind.selection),
  ],
);
```

`gatewayUri` and `hostSession` are supplied by your app. See the [integration guide](https://github.com/JhonaCodes/asystant-ai/blob/main/docs/public-api.md) for the authentication contract.

## Embed the chat

```dart
AsystantButton(assistant: assistant); // Opens a bottom sheet.

AsystantChat(
  assistant: assistant,
  strings: const AsystantStrings(spanish: false),
); // Mount inside a bounded section, drawer or full-screen Scaffold.
```

The host owns the assistant instance: closing the panel preserves the conversation. Call `assistant.dispose()` when its owner ends. Changing the login invalidates pending permissions and clears the conversation; initialize again for the new session.

## Tools and permissions

Implement `AsystantTool` or `TypedAsystantTool<T>`. Return a `ToolDefinition`, a read-only preview and an execution result. Tools execute inside the host app, never on the gateway. Confirmation is required by default; read-only tools can explicitly opt out. Use `requiresSelection` for user choices and `isAvailable` to control registration.

`ToolContext` exposes cancellation, selected values and an idempotency key. Your repository must still enforce authorization and protect asynchronous writes against duplicate effects. The SDK does not claim to reverse completed actions.

Cards support summary, entity, selection, permission and result presentations. The chat shows ordered tool steps, progress and error icons, and an action that changes from Send to Stop. Theme colors follow the host; use `AsystantTheme` for metrics and subclass `AsystantStrings` for custom wording or languages. English and Spanish are included.

## Backend and models

You can deploy the [reference Rust API](https://github.com/JhonaCodes/asystant-ai/tree/main/services/asystant_gateway), or use its [OpenAPI contract](https://github.com/JhonaCodes/asystant-ai/blob/main/services/asystant_gateway/openapi.yaml) as a guide for your own backend. It handles short-lived credentials, revocation, durable budgets and model policies per product, customer and user. See [deployment](https://github.com/JhonaCodes/asystant-ai/blob/main/docs/deployment.md) and [security](https://github.com/JhonaCodes/asystant-ai/blob/main/SECURITY.md).

The package does not include a hosted API, provider credentials or inference credits. OpenRouter is the initial integration; the server also contains OpenAI, Gemini, Anthropic and OpenCode adapters. Messages/Responses adapters currently deliver complete responses rather than incremental text. Provider availability and usage terms must be checked before enabling a model.

## Example

[example/lib/main.dart](example/lib/main.dart) runs without credentials using an explicitly simulated assistant response and a real local read-only tool. The repository also includes a complete [host app](https://github.com/JhonaCodes/asystant-ai/tree/main/examples/host_app) demonstrating draft confirmation in sheets, drawers and full screens.

## License

MIT. See [LICENSE](LICENSE).
