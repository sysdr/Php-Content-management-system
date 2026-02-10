#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
if docker compose ps 2>/dev/null | grep -q Up; then
  echo "Services already running. Use ./stop.sh first to restart."
  exit 0
fi
docker compose up -d
echo "Services started. Dashboard: http://localhost:8080/dashboard.php"
