#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
cd "$ROOT"
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --script tests/smoke_test.gd
mkdir -p artifacts/builds
"$GODOT" --headless --path . --export-release "Windows Desktop" artifacts/builds/EverdawnLife.exe
printf 'Validated parser/import, simulation smoke test, and Windows release export.\n'
