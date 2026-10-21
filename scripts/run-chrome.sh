#!/usr/bin/env bash
# Launch the locally built Chromium with an isolated profile.
set -euo pipefail

CHROME_DIR=$(cd "$(dirname "$0")/.." && pwd)
BIN=$CHROME_DIR/out/Release/chrome
PROFILE=${CHROME_PROFILE:-/tmp/mybrowser-profile}

exec "$BIN" --user-data-dir="$PROFILE" "$@"
