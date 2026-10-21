#!/usr/bin/env bash
# Watches the currently running build and, when it exits, hands over to
# build-chrome.sh which verifies/continues (and retries on failure).
set -u

CHROME_DIR=$(cd "$(dirname "$0")/.." && pwd)
LOG=$(cd "$CHROME_DIR/.." && pwd)/build-logs/watch.log
mkdir -p "$(dirname "$LOG")"

log() { echo "[$(date '+%F %T')] $*" | tee -a "$LOG"; }

pid=$(pgrep -f "autoninja.py -C out/Release" | head -1)

if [ -n "${pid:-}" ]; then
  log "watching build process pid=$pid"
  while kill -0 "$pid" 2>/dev/null; do
    sleep 15
  done
  log "build process pid=$pid exited; checking state"
else
  log "no running build found; checking state"
fi

exec "$CHROME_DIR/scripts/build-chrome.sh"
