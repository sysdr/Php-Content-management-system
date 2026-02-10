#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
for port in 8000; do
  if fuser "${port}/tcp" >/dev/null 2>&1; then
    fuser -k "${port}/tcp" 2>/dev/null || true
    echo "Stopped process on port ${port}."
  fi
done
