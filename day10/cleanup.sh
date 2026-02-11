#!/bin/bash
# cleanup.sh — Stop containers and remove unused Docker resources; remove project artifacts.
#
# - Stops: PHP dashboard (8081), RoadRunner (8080), project stop.sh, Docker containers.
# - Docker: stop containers, container/network/volume/image prune.
# - Removes: node_modules, venv, .pytest_cache, __pycache__, *.pyc, Istio-related files.
#
# Usage: ./cleanup.sh [--no-prune]   (use --no-prune to skip Docker volume/image prune)

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NO_PRUNE=false
[ "$1" = "--no-prune" ] && NO_PRUNE=true

echo "=== Stopping local servers (ports 8080, 8081) ==="
for port in 8080 8081; do
  if fuser "$port/tcp" >/dev/null 2>&1; then
    fuser -k "$port/tcp" 2>/dev/null || true
    echo "Stopped process on port $port"
  fi
done
pkill -f "rr serve" 2>/dev/null && echo "Stopped RoadRunner" || true
pkill -f "php -S.*8081" 2>/dev/null && echo "Stopped PHP dashboard (8081)" || true

echo ""
echo "=== Stopping project stop.sh (Day10) ==="
[ -f "$SCRIPT_DIR/HighScalePHPCMS/stop.sh" ] && (cd "$SCRIPT_DIR/HighScalePHPCMS" && ./stop.sh) 2>/dev/null || true

echo ""
echo "=== Stopping Docker containers and removing unused resources ==="
if command -v docker &>/dev/null; then
  # Stop project-related containers by name
  for name in high-scale-cms-kernel-registry high-scale-cms-kernel-registry-container; do
    if docker ps -a -q --filter "name=^${name}$" 2>/dev/null | grep -q .; then
      docker stop $(docker ps -a -q --filter "name=^${name}$") 2>/dev/null || true
      docker rm $(docker ps -a -q --filter "name=^${name}$") 2>/dev/null || true
      echo "Stopped and removed container(s): $name"
    fi
  done
  # Stop all remaining running containers
  RUNNING=$(docker ps -q 2>/dev/null) || true
  if [ -n "$RUNNING" ]; then
    docker stop $RUNNING 2>/dev/null && echo "Stopped all running containers" || true
  fi
  docker container prune -f 2>/dev/null && echo "Removed stopped containers" || true
  docker network prune -f 2>/dev/null && echo "Removed unused networks" || true
  if [ "$NO_PRUNE" = false ]; then
    docker volume prune -f 2>/dev/null && echo "Removed unused volumes" || true
    docker image prune -af 2>/dev/null && echo "Removed unused images" || true
  else
    echo "Skipped volume/image prune (--no-prune)"
  fi
else
  echo "Docker not found — skipping Docker cleanup."
fi

echo ""
echo "=== Removing project artifacts (node_modules, venv, .pytest_cache, __pycache__, .pyc, Istio) ==="
find "$SCRIPT_DIR" -maxdepth 6 -type d \( -name "node_modules" -o -name "venv" -o -name ".venv" -o -name ".pytest_cache" -o -name "__pycache__" \) ! -path "*/vendor/*" 2>/dev/null | while read -r d; do
  rm -rf "$d" 2>/dev/null && echo "Removed $d" || true
done
find "$SCRIPT_DIR" -maxdepth 6 -type f \( -name "*.pyc" -o -name "*.pyo" \) ! -path "*/vendor/*" -delete 2>/dev/null
echo "Removed .pyc/.pyo files (if any)"
find "$SCRIPT_DIR" -maxdepth 6 \( -type d -o -type f \) -iname "*istio*" ! -path "*/vendor/*" 2>/dev/null | while read -r f; do
  rm -rf "$f" 2>/dev/null && echo "Removed $f" || true
done

echo ""
echo "Cleanup done."
