#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
if [ -f roadrunner.pid ]; then
  PID=$(cat roadrunner.pid)
  kill "$PID" 2>/dev/null && echo "Stopped RoadRunner (PID $PID)." || true
  rm -f roadrunner.pid
fi
for port in 8080 8081; do
  if fuser "${port}/tcp" >/dev/null 2>&1; then
    fuser -k "${port}/tcp" 2>/dev/null || true
    echo "Stopped process on port ${port}."
  fi
done
rm -f php_dashboard.pid
