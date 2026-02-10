#!/bin/bash
# Build Day7 Resource Cleanup project (runs setup to generate all files)
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
exec bash "$SCRIPT_DIR/setup.sh"
