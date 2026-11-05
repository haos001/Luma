#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_macos
APP="$ROOT/dist/Luma.app"
if [[ ! -d "$APP" || ! -x "$ROOT/dist/lumactl" ]]; then
    printf 'Run bash scripts/build.sh first.\n' >&2
    exit 1
fi
codesign --verify --deep --strict "$APP"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
ARCH="$(lipo -archs "$APP/Contents/MacOS/Luma" | tr ' ' '-')"
NAME="Luma-${VERSION}-macOS-${ARCH}"
STAGE="$(mktemp -d "$ROOT/.build/release.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/$NAME"
ditto --norsrc "$APP" "$STAGE/$NAME/Luma.app"
cp dist/lumactl LICENSE docs/INSTALL.md docs/INSTALL.ru.md "$STAGE/$NAME/"
mkdir -p dist/releases
ARCHIVE="$ROOT/dist/releases/$NAME.zip"
ditto -c -k --norsrc --keepParent "$STAGE/$NAME" "$ARCHIVE"
cd "$ROOT/dist/releases"
shasum -a 256 "$NAME.zip" > "$NAME.zip.sha256"
printf 'Packaged: %s\n' "$ARCHIVE"
