#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
# Stop PHP server on 8000
for port in 8000; do
  if fuser "${port}/tcp" >/dev/null 2>&1; then
    fuser -k "${port}/tcp" 2>/dev/null || true
    echo "Stopped process on port ${port}."
  fi
done
# Stop native worker if running
if [ -f native_worker.pid ]; then
  WPID=$(cat native_worker.pid 2>/dev/null)
  [ -n "$WPID" ] && kill "$WPID" 2>/dev/null && echo "Stopped native worker PID $WPID."
  rm -f native_worker.pid
fi
if [ -f native_tail.pid ]; then
  TPID=$(cat native_tail.pid 2>/dev/null)
  [ -n "$TPID" ] && kill "$TPID" 2>/dev/null || true
  rm -f native_tail.pid
fi
if [ -f docker_tail.pid ]; then
  TPID=$(cat docker_tail.pid 2>/dev/null)
  [ -n "$TPID" ] && kill "$TPID" 2>/dev/null || true
  rm -f docker_tail.pid
fi
# Stop Docker container if running
if docker ps -q -f name=php-cms-worker-container 2>/dev/null | grep -q .; then
  docker stop php-cms-worker-container 2>/dev/null || true
  docker rm -f php-cms-worker-container 2>/dev/null || true
  echo "Stopped Docker container php-cms-worker-container."
fi
