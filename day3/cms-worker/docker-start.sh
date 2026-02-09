#!/bin/bash
# Run Day3 CMS with Docker (no local PHP needed)
cd "$(dirname "$0")"
echo "Building and starting Day3 CMS..."
docker build -t day3-cms . 2>/dev/null || docker build -t day3-cms .
docker run --rm -p 8000:8000 -p 8080:8080 --name day3-cms day3-cms
