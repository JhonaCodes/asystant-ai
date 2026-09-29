# asystant-ai

Embed an AI assistant inside an existing Flutter app. Launch it from a button or mount it in a section, bottom sheet, end drawer or full screen. The host chooses the assistant name and owns its lifetime. This repository contains the Flutter SDK.

| Component | Responsibility |
| --- | --- |
| [asystant_ai](packages/asystant_ai) | Flutter chat, genUI, permissions, themes and reactive_notifier state |
| [asystant_core](packages/asystant_core) | Pure Dart tools, protocol models, the `AssistantTransport` contract and its two transports: `OpenRouterTransport` and `ClaudeCliTransport` |
| [asystant-api](https://github.com/JhonaCodes/asystant-api) | Separate self-hosted service that issues short-lived, budget-limited OpenRouter keys to your backend; it does not proxy inference |
| [Host example](examples/host_app) | Botánica, a local-first app whose assistant uses `OpenRouterTransport`, local tools and host-owned cards |

## Quick start

```sh
flutter pub add asystant_ai
```

Extend `AsystantAI`, register your local tools, call `init` with a transport, then mount `AsystantButton(assistant: assistant)` or `AsystantChat(assistant: assistant)` in a bounded container:

- `OpenRouterTransport` talks to OpenRouter directly with a key returned by an `OpenRouterCredentialSource`. In production your backend authenticates the user and obtains that key from asystant-api (`POST /v1/managed/credentials`).
- `ClaudeCliTransport` runs the Claude Code CLI installed on a desktop machine with the user's own subscription, without an API key or backend.

See the [package guide](packages/asystant_ai/README.md) and [integration guide](docs/public-api.md).

Tools execute in your app using its existing services. The model only receives their schemas and proposes calls; the SDK validates each call and asks for permission before running it. It does not use MCP.

## Examples

[packages/asystant_ai/example/lib/main.dart](packages/asystant_ai/example/lib/main.dart) shows the integration without credentials: an explicitly simulated transport and a real local read-only tool.

The [host example](examples/host_app/README.md) connects to OpenRouter. For local testing, put a short-lived key in `examples/host_app/.env` as `OPENROUTER_API_KEY` (ignored by Git); without it the assistant opens and shows that it cannot connect.

```sh
flutter pub get
cd examples/host_app
flutter run -d <device> --dart-define-from-file=.env
```

## Backend

The SDK includes no hosted service, provider key or inference credit. With `OpenRouterTransport`, deploy [asystant-api](https://github.com/JhonaCodes/asystant-api) or any backend that returns the same credential JSON. Your backend keeps the asystant-api company key and authenticates each user; the app receives only that user's short-lived, budget-limited OpenRouter key.

- [asystant-api HTTP contract](https://github.com/JhonaCodes/asystant-api/blob/main/openapi.yaml)
- [Managed keys guide](https://github.com/JhonaCodes/asystant-api/blob/main/docs/managed-keys.md)
- [Deployment](docs/deployment.md)
- [Security controls](SECURITY.md)
- [Feature coverage and limitations](docs/feature-coverage.md)
- Historical records: [architecture](docs/proposal.md) and [verification](docs/implementation-verification.md) of the earlier ticket gateway

## License

MIT. See [LICENSE](LICENSE). Both Dart packages and the Rust service include their own license copy.

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
