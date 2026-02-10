#!/bin/bash
# Build Day5 PHP CMS Memory Leak Detection Docker image
set -e
cd "$(dirname "$0")"
PROJECT_NAME="php_cms_leak_detection"

if [ ! -d "$PROJECT_NAME" ]; then
    echo "Project not found. Run ./setup.sh first."
    exit 1
fi

if ! command -v docker &>/dev/null; then
    echo "Docker not found. Install Docker or use direct PHP run only."
    exit 1
fi

docker build -t php-leak-detector "$PROJECT_NAME" -f "$PROJECT_NAME/docker/Dockerfile"
echo "Build complete. Image: php-leak-detector"
