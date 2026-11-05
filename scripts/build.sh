#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_app_sdk
swift build -c release -Xswiftc -gnone "${SWIFT_FLAGS[@]}"
BIN="$(swift build -c release --show-bin-path "${SWIFT_FLAGS[@]}")"
APP="$ROOT/dist/Luma.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/LumaApp" "$APP/Contents/MacOS/Luma"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp "$BIN/lumactl" dist/lumactl
# Do not distribute build-machine debug paths or separate debugging symbols.
strip -S "$APP/Contents/MacOS/Luma" dist/lumactl
swift scripts/CreateIcon.swift "$ROOT/.build/AppIcon.iconset"
iconutil -c icns .build/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$APP"
codesign --verify --deep --strict "$APP"
printf 'Built: %s\nCLI: %s\n' "$APP" "$ROOT/dist/lumactl"
