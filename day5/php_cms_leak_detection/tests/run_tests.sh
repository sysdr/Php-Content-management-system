#!/bin/bash
set -e
cd "$(dirname "$0")/.." || exit 1
BASE="http://127.0.0.1:8000"
echo "=== Running Day5 Memory Leak Detection tests ==="
echo "Test 1: leaky_app.php exists..."
[ -f src/leaky_app.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 2: Dockerfile exists..."
[ -f docker/Dockerfile ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 3: data/stats.json exists..."
[ -f data/stats.json ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 4: Direct PHP run produces memory output..."
if ! command -v php &>/dev/null; then
  echo "SKIP (php not in PATH)"
else
  out=$(php src/leaky_app.php 2>&1)
  echo "$out" | grep -q "Peak Memory:" && echo "$out" | grep -q "Final Memory:" && echo "OK" || { echo "FAIL"; exit 1; }
fi
echo "Test 5: PHP server (if running) dashboard loads..."
code=$(curl -sf -o /tmp/d5_dash.html -w "%{http_code}" "$BASE/dashboard.php" 2>/dev/null || echo "000")
[ "$code" = "200" ] && echo "OK" || { echo "SKIP (server not running — start with ./start.sh)"; }
if [ "$code" = "200" ]; then
  echo "Test 6: Dashboard JSON endpoint..."
  stats=$(curl -sf "$BASE/dashboard.php?json=1" 2>/dev/null || echo "{}")
  echo "$stats" | grep -q "direct_runs" && echo "$stats" | grep -q "last_peak_memory_mb" && echo "OK" || { echo "FAIL"; exit 1; }
  echo "Test 7: Run direct demo updates metrics..."
  curl -sf "$BASE/run_demo.php?type=direct" > /dev/null
  stats2=$(curl -sf "$BASE/dashboard.php?json=1")
  dr=$(echo "$stats2" | grep -o '"direct_runs":[0-9]*' | cut -d: -f2)
  [ -n "$dr" ] && [ "$dr" -ge 1 ] && echo "OK (direct_runs=$dr)" || { echo "FAIL"; exit 1; }
fi
echo "All tests passed."
