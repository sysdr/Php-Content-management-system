#!/bin/bash
# Build Day8 PHP CMS Worker (signal handling) Docker image
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
PROJECT_DIR="high_scale_cms_day8"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "Project not found. Run ./setup.sh first."
    exit 1
fi

if ! command -v docker &>/dev/null; then
    echo "Docker not found. Install Docker or use native PHP run only."
    exit 1
fi

cd "$PROJECT_DIR"
docker build -t php-cms-worker .
echo "Build complete. Image: php-cms-worker"
