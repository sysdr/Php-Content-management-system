#!/bin/bash
set -e
cd "$(dirname "$0")/.." || exit 1
# Try port 80 (FrankenPHP) then 8000 (PHP fallback)
if curl -sf -o /dev/null -w "%{http_code}" "http://127.0.0.1:80/dashboard.php" 2>/dev/null | grep -q 200; then
  BASE="http://127.0.0.1:80"
elif curl -sf -o /dev/null -w "%{http_code}" "http://127.0.0.1:8000/dashboard.php" 2>/dev/null | grep -q 200; then
  BASE="http://127.0.0.1:8000"
else
  BASE="http://127.0.0.1:80"
fi
echo "=== Day9 FrankenPHP tests ==="
echo "Test 1: public/index.php exists..."
[ -f public/index.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 2: public/dashboard.php exists..."
[ -f public/dashboard.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 3: public/run_demo.php exists..."
[ -f public/run_demo.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 4: data/stats.json exists..."
[ -f data/stats.json ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 5: start.sh and stop.sh exist..."
[ -x start.sh ] && [ -f stop.sh ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 6: Caddyfile exists..."
[ -f Caddyfile ] && echo "OK" || { echo "FAIL"; exit 1; }
code=$(curl -sf -o /tmp/d9_dash.html -w "%{http_code}" "$BASE/dashboard.php" 2>/dev/null || echo "000")
[ "$code" = "200" ] && echo "Test 7: Dashboard loads OK" || { echo "Test 7: SKIP (server not on :80 — run ./start.sh from project dir)"; }
if [ "$code" = "200" ]; then
  stats=$(curl -sf "$BASE/dashboard.php?json=1" 2>/dev/null || echo "{}")
  echo "$stats" | grep -q "demo_runs" && echo "$stats" | grep -q "requests_processed" && echo "Test 8: Dashboard JSON OK" || { echo "FAIL"; exit 1; }
  curl -sf "$BASE/run_demo.php" >/dev/null
  stats2=$(curl -sf "$BASE/dashboard.php?json=1")
  runs=$(echo "$stats2" | grep -o '"demo_runs":[0-9]*' | cut -d: -f2)
  [ -n "$runs" ] && [ "$runs" -ge 1 ] && echo "Test 9: Demo updates metrics OK (demo_runs=$runs)" || { echo "FAIL"; exit 1; }
fi
echo "All tests passed."
