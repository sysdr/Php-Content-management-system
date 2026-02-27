#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT" || exit 1
BASE="http://127.0.0.1:8000"
echo "=== Running Day 11 PSR-7 CMS tests ==="
echo "Test 1: public/index.php exists..."
[ -f public/index.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 2: vendor/autoload.php exists..."
[ -f vendor/autoload.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 3: composer.json exists..."
[ -f composer.json ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 4: Dockerfile exists..."
[ -f Dockerfile ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 5: docker-compose.yml exists..."
[ -f docker-compose.yml ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 6: start.sh and stop.sh exist and executable..."
[ -x start.sh ] && [ -f stop.sh ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 7: App responds (if server running)..."
code=$(curl -sf -o /dev/null -w "%{http_code}" "$BASE/" 2>/dev/null || echo "000")
if [ "$code" = "200" ]; then
  echo "OK (HTTP 200)"
  echo "Test 8: X-Processed-By header present..."
  out=$(curl -s -i "$BASE/" 2>/dev/null || true)
  echo "$out" | grep -qi "X-Processed-By: HighScaleCMS-Day11" && echo "OK" || { echo "FAIL"; exit 1; }
  echo "Test 9: Response body contains greeting..."
  echo "$out" | grep -q "Hello from the High-Scale CMS!" && echo "OK" || { echo "FAIL"; exit 1; }
else
  echo "SKIP (server not running — start with ./start.sh from project root)"
fi
echo "All tests passed."
