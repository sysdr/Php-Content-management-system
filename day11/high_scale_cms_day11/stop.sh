#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
if [ -f .php-server.pid ]; then
  pid=$(cat .php-server.pid)
  kill "$pid" 2>/dev/null || true
  rm -f .php-server.pid
fi
fuser -k 8000/tcp 2>/dev/null || true
docker compose down 2>/dev/null || true
echo "Stopped PHP server and Docker (if any)."
