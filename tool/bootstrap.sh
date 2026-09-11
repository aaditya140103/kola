#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed or not on PATH." >&2
  echo "Install Flutter first, then run: bash tool/bootstrap.sh" >&2
  exit 1
fi

flutter create \
  --project-name kola \
  --org app.kola \
  --platforms android,ios,linux,macos,windows \
  .

flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test

echo "Kola bootstrap complete. Run with: flutter run"
