#!/bin/bash
# Build Day4 CMS Docker image
set -e
cd "$(dirname "$0")"

if [ ! -d "cms-worker-day4" ]; then
    echo "Project not found. Run ./setup.sh first."
    exit 1
fi

cd cms-worker-day4
docker build -t day4-cms .
echo "Build complete. Image: day4-cms"
