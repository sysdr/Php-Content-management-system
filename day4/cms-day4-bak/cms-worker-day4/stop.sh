#!/bin/bash
cd "$(dirname "$0")" 2>/dev/null || true
# Stop Docker container if running
docker rm -f day4-cms 2>/dev/null && echo "Stopped day4-cms container" || true
for port in 8000 8080; do
  pid=$(fuser "$port/tcp" 2>/dev/null | tr -d ' ')
  [ -n "$pid" ] && kill $pid 2>/dev/null && echo "Stopped process on port $port (PID $pid)"
done
pkill -f "rr serve.*\.rr\.yaml" 2>/dev/null && echo "Stopped RoadRunner"
echo "Cleanup done."
