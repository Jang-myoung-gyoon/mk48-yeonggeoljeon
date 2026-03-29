#!/usr/bin/env bash
set -euo pipefail

PORT="${RALPHTHON_WEB_PORT:-7357}"
BASE_URL="${RALPHTHON_BASE_URL:-http://localhost:${PORT}}"
SERVER_PID=""

cleanup() {
  if [[ -n "${SERVER_PID}" ]]; then
    kill "${SERVER_PID}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

if [[ -z "${RALPHTHON_BASE_URL:-}" ]]; then
  flutter build web >/tmp/ralphthon-playwright-build.log 2>&1
  python3 - <<'PY' "${PORT}" "$(pwd)/build/web" >/tmp/ralphthon-playwright-server.log 2>&1 &
import os
import sys
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

port = int(sys.argv[1])
root = Path(sys.argv[2]).resolve()

class SpaHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(root), **kwargs)

    def do_GET(self):
        target = (root / self.path.lstrip('/')).resolve()
        if self.path == '/' or not target.exists() or target.is_dir():
            self.path = '/index.html'
        return super().do_GET()

ThreadingHTTPServer(('0.0.0.0', port), SpaHandler).serve_forever()
PY
  SERVER_PID="$!"
  for _ in {1..60}; do
    if curl -fsS "${BASE_URL}" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
fi

RALPHTHON_BASE_URL="${BASE_URL}" npx -y -p playwright node tooling/playwright/route_sweep.mjs
