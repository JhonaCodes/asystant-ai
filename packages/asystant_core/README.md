# asystant_core

Typed local tools, session contracts and an HTTP/SSE gateway client for embedded AI assistants. Pure Dart: usable from Flutter mobile, web and desktop applications, or from a Dart service.

## Install

```sh
dart pub add asystant_core
```

For a ready-to-embed Flutter chat, use [asystant_ai](https://pub.dev/packages/asystant_ai).

## Define a local tool

Tools run in your application, using its existing authorization and services. The gateway receives only their schemas. Mutating tools require confirmation by default.

```dart
import 'package:asystant_core/asystant_core.dart';

class ReadWorkspaceTool extends AsystantTool {
  const ReadWorkspaceTool();

  @override
  ToolDefinition get definition => const ToolDefinition(
    name: 'read_workspace',
    description: 'Read the current workspace name.',
    fields: [],
  );

  @override
  bool get requiresConfirmation => false;

  @override
  Future<Result<AssistantCard, AssistantFailure>> preview(
    ToolArguments arguments,
  ) async => Ok(const AssistantCard(title: 'Current workspace'));

  @override
  Future<Result<ToolOutcome, AssistantFailure>> execute(
    ToolArguments arguments,
    ToolContext context,
  ) async {
    context.checkCanceled();
    return Ok(const ToolOutcome(modelContent: 'Example workspace'));
  }
}
```

Use `TypedAsystantTool<T>` to decode tool arguments into a domain type. Definitions reject duplicate names, unknown arguments and invalid scalar types. For writes, check cancellation immediately before committing and pass `context.idempotencyKey` to your own repository. Cancellation does not undo effects already committed.

## Connect authentication

Implement `SessionSource`, or use `CallbackSessionSource`, to provide the current login identity, a stream of login changes and fresh signed tickets from your existing backend. Never sign tickets or embed provider keys in a client application.

`GatewayTransport(baseUri: yourGatewayUri, sessionSource: yourSession)` exchanges those tickets for short-lived credentials, renews them before expiry and registers the tools. `initialize(models: [])` delegates model selection to the server. The server may assign a fixed model or permit a bounded selection. Keep one transport per assistant; call `dispose()` when its owner is destroyed.

## Reference API

You can use the [Rust gateway](https://github.com/JhonaCodes/asystant-api) as a deployment-ready starting point or as a guide for implementing your own compatible API. Read its [HTTP contract](https://github.com/JhonaCodes/asystant-api/blob/main/openapi.yaml), [deployment guide](https://github.com/JhonaCodes/asystant-api/blob/main/docs/deployment.md) and [security controls](https://github.com/JhonaCodes/asystant-ai/blob/main/SECURITY.md). It is self-hosted software; this package does not include a hosted service or provider credits.

OpenRouter is the initial provider. Other adapters and their streaming limitations are documented in the gateway. Application authorization remains the responsibility of your local tool implementations.

## Example and license

See [example/asystant_core_example.dart](example/asystant_core_example.dart) for a runnable local-tool example. Licensed under MIT; see [LICENSE](LICENSE).
