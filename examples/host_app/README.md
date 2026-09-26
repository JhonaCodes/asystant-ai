# Embedded assistant host example

An English-language Flutter app demonstrating the assistant inside an existing workspace. Launch it in a bottom sheet, side panel or full screen. AI responses are explicitly simulated; the local tool creates drafts in memory after user confirmation. No provider keys are required.

From the repository root:

```sh
flutter pub get
cd examples/host_app
flutter run -d chrome
```

For a network-backed integration, replace `DemoTransport` with `GatewayTransport` and connect your existing login to `SessionSource`. Follow the [integration guide](../../docs/public-api.md) and the [reference Rust API](https://github.com/JhonaCodes/asystant-api).
