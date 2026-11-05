#!/bin/bash
# Shared build configuration. Source this file; do not run it directly.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export CLANG_MODULE_CACHE_PATH="$ROOT/.build/clang-cache"
export SWIFT_MODULECACHE_PATH="$ROOT/.build/swift-cache"
SWIFT_FLAGS=(--cache-path .build/cache --config-path .build/config --security-path .build/security)

require_macos() {
    if [[ "$(uname -s)" != Darwin ]]; then
        printf 'Luma requires macOS and Apple development tools.\n' >&2
        exit 1
    fi
    if ! xcrun --find swift >/dev/null 2>&1; then
        printf 'Install Xcode or Command Line Tools, then select the developer directory.\n' >&2
        exit 1
    fi
}

require_app_sdk() {
    require_macos
    local sdk
    sdk="$(xcrun --sdk macosx --show-sdk-version)"
    if [[ "${sdk%%.*}" -lt 26 ]]; then
        printf 'Building the app requires macOS SDK 26+ (Xcode 26+ or corresponding Command Line Tools). Found: %s\n' "$sdk" >&2
        exit 1
    fi
}
