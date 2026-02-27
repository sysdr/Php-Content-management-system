#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"
docker compose down 2>/dev/null || docker-compose down 2>/dev/null || true
echo "Containers stopped."
