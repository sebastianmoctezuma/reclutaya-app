#!/usr/bin/env bash
# Los cuatro checks de la casa. Nada se sube en rojo.
set -euo pipefail
cd "$(dirname "$0")/.."
dart format --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test
flutter build apk --debug --dart-define-from-file=defines/prod.example.json >/dev/null
echo "verificar: todo en verde"
