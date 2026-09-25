#!/usr/bin/env sh
set -eu
flutter pub get
flutter analyze
dart test packages/asystant_core/test
flutter test packages/asystant_ai/test examples/host_app/test
