#!/usr/bin/env sh
set -eu
flutter pub get
flutter analyze
dart test packages/asystant_core/test
flutter test packages/asystant_ai/test examples/host_app/test
cargo test --manifest-path services/asystant_gateway/Cargo.toml --test contracts --test admission
cargo clippy --manifest-path services/asystant_gateway/Cargo.toml --all-targets -- -D warnings
if [ -n "${ASYSTANT_TEST_DATABASE_URL:-}" ]; then
  cargo test --manifest-path services/asystant_gateway/Cargo.toml --test database --test http_api --test client_models
fi
