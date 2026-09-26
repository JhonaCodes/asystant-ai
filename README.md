# asystant-ai

The standalone Rust gateway now lives in [asystant-api](https://github.com/JhonaCodes/asystant-api), using SQLite with a persistent volume. This repository contains the Flutter SDK.

Embed an AI assistant inside an existing Flutter app. Launch it from a button or mount it in a section, bottom sheet, end drawer or full screen. The host chooses the assistant name and owns its lifetime.

| Component | Responsibility |
| --- | --- |
| [asystant_ai](packages/asystant_ai) | Flutter chat, genUI, permissions, themes and reactive_notifier state |
| [asystant_core](packages/asystant_core) | Pure Dart tools, protocol models, session contracts and gateway transport |
| [Rust gateway](https://github.com/JhonaCodes/asystant-api) | Temporary credentials, model policies, provider adapters and durable budgets |
| [Host example](examples/host_app) | An embedded assistant with a real in-memory draft tool and simulated AI responses |

## Quick start

```sh
flutter pub add asystant_ai
```

Extend `AsystantAI`, register your local tools, initialize with a `GatewayTransport` after host authentication, then mount `AsystantButton(assistant: assistant)` or `AsystantChat(assistant: assistant)` in a bounded container. See the [package guide](packages/asystant_ai/README.md) and [integration contract](docs/public-api.md).

Tools execute in your app using its existing services. The gateway passes schemas to the model and returns proposed calls; it never executes application code and does not use MCP.

## Run the offline example

```sh
flutter pub get
cd examples/host_app
flutter run -d chrome
```

The example explicitly identifies simulated responses. Draft creation is a real local operation in memory and requires the same permission flow used by a network-backed assistant.

## Build your backend

You can deploy the Rust gateway or use it as a reference for your own compatible API. Each product integrates ticket issuance with its existing login. Provider secrets stay on the server; Flutter receives only short-lived credentials. There is no bundled hosted service or inference credit.

- [Public HTTP contract](https://github.com/JhonaCodes/asystant-api/blob/main/openapi.yaml)
- [Authentication and provider guide](https://github.com/JhonaCodes/asystant-api)
- [Deployment](docs/deployment.md)
- [Security controls and OWASP scope](SECURITY.md)
- [Architecture](docs/proposal.md)
- [Feature coverage and limitations](docs/feature-coverage.md)
- [Verification record](docs/implementation-verification.md)

## License

MIT. See [LICENSE](LICENSE). Both Dart packages and the Rust service include their own license copy.

## Reports and prompt customization

Application personality is supplied through `AsystantAI.systemPrompts`; scoped
context can be added with `additionalSystemPrompts` during `init()`. The SDK and
Rust gateway apply baseline safety guidance independently. See the
[integration guide](https://github.com/JhonaCodes/asystant-ai/blob/main/docs/public-api.md).

Cards now support typed bar and line charts, with accessible labels, units and
source notes. These are English Flutter golden renders using example data:

![Mobile report with bars and trend](https://raw.githubusercontent.com/JhonaCodes/asystant-ai/main/packages/asystant_ai/test/goldens/report_390.png)

[Desktop golden](https://raw.githubusercontent.com/JhonaCodes/asystant-ai/main/packages/asystant_ai/test/goldens/report_900.png)

See [model experience and verification](https://github.com/JhonaCodes/asystant-ai/blob/main/docs/model-experience.md)
for owner-reported GPT-OSS 20B/120B results and the boundary of automated testing.
