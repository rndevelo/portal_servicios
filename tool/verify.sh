#!/usr/bin/env bash
set -euo pipefail
flutter --version
flutter pub get --enforce-lockfile
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --coverage
