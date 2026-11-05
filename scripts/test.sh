#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_macos
# Pure checks only. No USB commands or access to the user's saved colors.
swift run "${SWIFT_FLAGS[@]}" LightCoreChecks
