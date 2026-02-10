#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" 2>/dev/null || true
docker compose down 2>/dev/null
echo "Services stopped."
