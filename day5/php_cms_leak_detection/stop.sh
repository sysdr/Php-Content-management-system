#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" 2>/dev/null || true
for port in 8000; do
  pid=$(fuser "$port/tcp" 2>/dev/null | tr -d ' ')
  [ -n "$pid" ] && kill $pid 2>/dev/null && echo "Stopped process on port $port (PID $pid)"
done
command -v docker &>/dev/null && docker rm -f php-leak-detector &>/dev/null && echo "Stopped Docker container php-leak-detector" || true
echo "Cleanup done."
