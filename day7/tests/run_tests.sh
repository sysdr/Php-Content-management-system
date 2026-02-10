#!/bin/bash
set -e
cd "$(dirname "$0")/.." || exit 1
BASE="http://127.0.0.1:8000"
echo "=== Day7 Resource Cleanup tests ==="
echo "Test 1: src/ResourceWatcher.php exists..."
[ -f src/ResourceWatcher.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 2: src/App.php exists..."
[ -f src/App.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 3: data/stats.json exists..."
[ -f data/stats.json ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 4: public/dashboard.php exists..."
[ -f public/dashboard.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 5: public/run_demo.php exists..."
[ -f public/run_demo.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 6: Direct PHP run produces destruct log..."
if command -v php &>/dev/null; then
  rm -f logs/resource_events.log logs/app_events.log
  php src/App.php >/dev/null 2>&1
  [ -f logs/resource_events.log ] && grep -q "automatically released via __destruct" logs/resource_events.log && echo "OK" || { echo "FAIL"; exit 1; }
else
  echo "SKIP (php not in PATH)"
fi
echo "Test 7: Dashboard (if server running) loads..."
code=$(curl -sf -o /tmp/d7_dash.html -w "%{http_code}" "$BASE/dashboard.php" 2>/dev/null || echo "000")
[ "$code" = "200" ] && echo "OK" || { echo "SKIP (server not running — start with ./start.sh)"; }
if [ "$code" = "200" ]; then
  echo "Test 8: Dashboard JSON endpoint..."
  stats=$(curl -sf "$BASE/dashboard.php?json=1" 2>/dev/null || echo "{}")
  echo "$stats" | grep -q "request_runs" && echo "$stats" | grep -q "last_destruct_calls" && echo "OK" || { echo "FAIL"; exit 1; }
  echo "Test 9: Run demo updates metrics..."
  curl -sf "$BASE/run_demo.php" > /dev/null
  stats2=$(curl -sf "$BASE/dashboard.php?json=1")
  runs=$(echo "$stats2" | grep -o '"request_runs":[0-9]*' | cut -d: -f2)
  [ -n "$runs" ] && [ "$runs" -ge 1 ] && echo "OK (request_runs=$runs)" || { echo "FAIL"; exit 1; }
fi
echo "All tests passed."
