#!/usr/bin/env bash
# ビルドしてからブラウザを起動する（開発用の入口）。
# 追加の引数はそのまま Chrome に渡る。
#
#   ./scripts/dev.sh
#   ./scripts/dev.sh --headless=new --dump-dom about:blank
#   JOBS=6 ./scripts/dev.sh
#
# ビルドだけしたいときは build-chrome.sh、起動だけなら run-chrome.sh を使う。
set -euo pipefail

CHROME_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$CHROME_DIR"

start=$(date +%s)

echo "==> build  $(date '+%F %T')"
if ! ./scripts/build-chrome.sh; then
  echo "==> build failed; see build-logs/supervisor.log" >&2
  exit 1
fi
echo "==> build done in $(( $(date +%s) - start ))s"

echo "==> $(./scripts/run-chrome.sh --version)"

# exec で Chrome にプロセスを引き継ぐ（余計なシェルを残さない）。
exec ./scripts/run-chrome.sh "$@"
