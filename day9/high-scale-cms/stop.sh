#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
for port in 80 8000; do
  if fuser "${port}/tcp" >/dev/null 2>&1; then
    fuser -k "${port}/tcp" 2>/dev/null || true
    echo "Stopped process on port ${port}."
  fi
done
if pgrep -f "frankenphp run" >/dev/null; then
  pkill -f "frankenphp run" 2>/dev/null || true
  echo "Stopped FrankenPHP."
fi
rm -f frankenphp.pid
if docker ps -q -f name=cms-frankenphp-app 2>/dev/null | grep -q .; then
  docker stop cms-frankenphp-app 2>/dev/null || true
  docker rm -f cms-frankenphp-app 2>/dev/null || true
  echo "Stopped Docker container cms-frankenphp-app."
fi
