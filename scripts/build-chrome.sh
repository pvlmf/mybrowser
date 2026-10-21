#!/usr/bin/env bash
# Chromium build supervisor: retries transient failures, throttles on OOM,
# and stops on repeated compile errors. Logs go to build-logs/.
set -u -o pipefail

CHROME_DIR=$(cd "$(dirname "$0")/.." && pwd)
CHROME_SRC=$CHROME_DIR
export PATH=/home/pvlmf/depot_tools:$PATH
OUT=out/Release
LOG_DIR=$CHROME_DIR/build-logs
mkdir -p "$LOG_DIR"

MAX_ATTEMPTS=${MAX_ATTEMPTS:-6}
JOBS=${JOBS:-8}
MIN_JOBS=2

cd "$CHROME_SRC" || exit 1

log() { echo "[$(date '+%F %T')] $*" | tee -a "$LOG_DIR/supervisor.log"; }

# Never run two builds at once.
if pgrep -f "autoninja.py -C $OUT" >/dev/null; then
  log "Another autoninja for $OUT is already running; aborting."
  exit 4
fi

attempt=0
while (( attempt < MAX_ATTEMPTS )); do
  attempt=$((attempt + 1))

  # Leave some headroom before starting; shrink parallelism if memory is tight.
  avail_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
  if (( avail_kb < 3500000 )) && (( JOBS > MIN_JOBS )); then
    JOBS=$((JOBS - 2)); (( JOBS < MIN_JOBS )) && JOBS=$MIN_JOBS
    log "Low memory (${avail_kb}kB available): reducing jobs to $JOBS"
  fi

  logfile="$LOG_DIR/build-$(date +%Y%m%d-%H%M%S).log"
  log "attempt $attempt/$MAX_ATTEMPTS: autoninja -C $OUT -j $JOBS chrome  (log: $logfile)"
  autoninja -C "$OUT" -j "$JOBS" chrome >"$logfile" 2>&1
  rc=$?

  if (( rc == 0 )); then
    log "BUILD SUCCEEDED (attempt $attempt)"
    ls -lh "$OUT/chrome" 2>/dev/null | tee -a "$LOG_DIR/supervisor.log"
    exit 0
  fi
  log "attempt $attempt failed (exit code $rc)"

  if grep -qE "Killed|out of memory|OOM killer|virtual memory exhausted" "$logfile"; then
    reason=oom
  elif grep -qE "^FAILED:|error: " "$logfile"; then
    reason=compile
  elif grep -qE "interrupt by signal|Terminated|unexpected disconnect|RPC failed|CIPD|timed out|Connection reset" "$logfile"; then
    reason=transient
  else
    reason=unknown
  fi
  log "failure classified as: $reason"

  case $reason in
    oom)
      JOBS=$((JOBS - 2)); (( JOBS < MIN_JOBS )) && JOBS=$MIN_JOBS
      log "OOM detected: retrying with -j $JOBS after cooldown"
      sleep 30
      ;;
    compile)
      if (( attempt >= 2 )); then
        log "Repeated compile error; stopping. Inspect: $logfile"
        exit 2
      fi
      log "Compile error: one incremental retry before giving up"
      sleep 5
      ;;
    *)
      log "Transient/unknown failure: retrying after 60s"
      sleep 60
      ;;
  esac
done

log "Giving up after $MAX_ATTEMPTS attempts"
exit 3
