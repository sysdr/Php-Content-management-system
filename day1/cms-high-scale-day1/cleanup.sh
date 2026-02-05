#!/bin/bash
# Stop local app servers (PHP, RoadRunner) and Docker resources.
# Removes unused containers, volumes, images.
# Also removes node_modules, venv, .pytest_cache, .pyc, Istio artifacts from project.

set -e
DOCKER="${DOCKER:-docker}"
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "=== Removing project artifacts (node_modules, venv, .pytest_cache, .pyc, Istio) ==="
for dir in node_modules venv .venv .pytest_cache __pycache__; do
  if [ -d "$PROJECT_ROOT/$dir" ]; then
    rm -rf "$PROJECT_ROOT/$dir" && echo "Removed $dir"
  fi
done
find "$PROJECT_ROOT" -maxdepth 4 -type f -name "*.pyc" -delete 2>/dev/null && true
find "$PROJECT_ROOT" -maxdepth 4 -type d -name "__pycache__" 2>/dev/null | while read -r d; do rm -rf "$d" 2>/dev/null; done || true
# Istio-related files/dirs (skip vendor)
find "$PROJECT_ROOT" -maxdepth 4 -name "*istio*" ! -path "*/vendor/*" 2>/dev/null | while read -r f; do rm -rf "$f" 2>/dev/null; done || true

echo ""
echo "=== Stopping local servers (ports 8000, 8080) ==="
for port in 8000 8080; do
  pid=$(fuser "$port/tcp" 2>/dev/null | tr -d ' ')
  [ -n "$pid" ] && kill $pid 2>/dev/null && echo "Stopped process on port $port (PID $pid)" || true
done
pkill -f "rr serve" 2>/dev/null && echo "Stopped RoadRunner" || true

echo ""
echo "=== Stopping Docker containers ==="
CONTAINERS=$($DOCKER ps -q 2>/dev/null) || true
if [ -n "$CONTAINERS" ]; then
  $DOCKER stop $CONTAINERS 2>/dev/null && echo "Stopped running containers"
else
  echo "No running containers (or Docker not available)"
fi
$DOCKER compose down 2>/dev/null || true

echo ""
echo "=== Removing unused Docker resources ==="
$DOCKER container prune -f 2>/dev/null && echo "Removed stopped containers" || echo "Docker prune skipped (not running?)"
$DOCKER volume prune -f 2>/dev/null && echo "Removed unused volumes" || true
$DOCKER image prune -af 2>/dev/null && echo "Removed unused images" || true
$DOCKER network prune -f 2>/dev/null && echo "Removed unused networks" || true

echo ""
echo "Cleanup done."
