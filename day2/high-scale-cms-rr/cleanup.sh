#!/bin/bash
# Stop local servers (PHP, RoadRunner), stop Docker containers,
# remove unused Docker resources (containers, volumes, images, networks),
# and remove project artifacts: node_modules, venv, .pytest_cache, .pyc, Istio.

set -e
DOCKER="${DOCKER:-docker}"
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

echo "=== Stopping local servers (ports 8000, 8080) ==="
[ -x "./stop.sh" ] && ./stop.sh || true
for port in 8000 8080; do
  pid=$(fuser "$port/tcp" 2>/dev/null | tr -d ' ')
  [ -n "$pid" ] && kill $pid 2>/dev/null && echo "Stopped process on port $port (PID $pid)" || true
done
pkill -f "rr serve" 2>/dev/null && echo "Stopped RoadRunner" || true

echo ""
echo "=== Stopping Docker containers ==="
if command -v "$DOCKER" >/dev/null 2>&1; then
  CONTAINERS=$($DOCKER ps -aq 2>/dev/null) || true
  if [ -n "$CONTAINERS" ]; then
    $DOCKER stop $CONTAINERS 2>/dev/null && echo "Stopped all containers" || true
  else
    echo "No containers to stop"
  fi
  $DOCKER compose down 2>/dev/null || true
else
  echo "Docker not available, skipping container stop"
fi

echo ""
echo "=== Removing project artifacts (node_modules, venv, .pytest_cache, .pyc, Istio) ==="
for dir in node_modules venv .venv .pytest_cache __pycache__; do
  if [ -d "$PROJECT_ROOT/$dir" ]; then
    rm -rf "$PROJECT_ROOT/$dir" && echo "Removed $dir"
  fi
done
find "$PROJECT_ROOT" -maxdepth 4 -type f -name "*.pyc" ! -path "*/vendor/*" -delete 2>/dev/null && true
find "$PROJECT_ROOT" -maxdepth 4 -type d -name "__pycache__" ! -path "*/vendor/*" 2>/dev/null | while read -r d; do rm -rf "$d" 2>/dev/null; done || true
find "$PROJECT_ROOT" -maxdepth 4 -name "*istio*" ! -path "*/vendor/*" 2>/dev/null | while read -r f; do rm -rf "$f" 2>/dev/null; done || true

echo ""
echo "=== Removing unused Docker resources ==="
if command -v "$DOCKER" >/dev/null 2>&1; then
  $DOCKER container prune -f 2>/dev/null && echo "Removed stopped containers" || true
  $DOCKER volume prune -f 2>/dev/null && echo "Removed unused volumes" || true
  $DOCKER image prune -af 2>/dev/null && echo "Removed unused images" || true
  $DOCKER network prune -f 2>/dev/null && echo "Removed unused networks" || true
else
  echo "Docker not available, skipping prune"
fi

echo ""
echo "Cleanup done."
