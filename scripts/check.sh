#!/usr/bin/env sh
set -eu
flutter pub get
flutter analyze
dart test packages/asystant_core/test
flutter test packages/asystant_ai/test
(cd examples/host_app && flutter test test)
