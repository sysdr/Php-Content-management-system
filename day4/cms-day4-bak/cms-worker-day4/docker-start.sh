#!/bin/bash
# Run Day4 CMS with Docker (no local PHP needed)
cd "$(dirname "$0")"
echo "Stopping any existing containers..."
docker rm -f day4-cms 2>/dev/null || true
echo "Building and starting Day4 CMS..."
docker build -t day4-cms .
docker run --rm -p 8000:8000 -p 8080:8080 --name day4-cms day4-cms
