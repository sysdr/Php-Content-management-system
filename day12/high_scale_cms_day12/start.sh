#!/bin/bash
set -e
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"
if command -v docker compose &>/dev/null; then
  docker compose up -d
elif command -v docker-compose &>/dev/null; then
  docker-compose up -d
else
  echo "Error: docker compose or docker-compose not found."
  exit 1
fi
echo "Containers started. Nginx at http://localhost:8080"
