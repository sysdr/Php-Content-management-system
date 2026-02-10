#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LAB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$LAB_ROOT" || exit 1
BASE="http://127.0.0.1:8080"
echo "=== Running Day6 OPcache & JIT Lab tests ==="
echo "Test 1: web/index.php exists..."
[ -f web/index.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 2: web/dashboard.php exists..."
[ -f web/dashboard.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 3: web/run_demo.php exists..."
[ -f web/run_demo.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 4: cli/cpu_intensive_task.php exists..."
[ -f cli/cpu_intensive_task.php ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 5: data/stats.json exists..."
[ -f data/stats.json ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 6: start.sh and stop.sh exist..."
[ -x start.sh ] && [ -f stop.sh ] && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 7: Dashboard (if services running) loads..."
code=$(curl -sf -o /tmp/d6_dash.html -w "%{http_code}" "$BASE/dashboard.php" 2>/dev/null || echo "000")
[ "$code" = "200" ] && echo "OK" || { echo "SKIP (services not running — start with ./start.sh)"; }
if [ "$code" = "200" ]; then
  echo "Test 8: Dashboard JSON endpoint..."
  stats=$(curl -sf "$BASE/dashboard.php?json=1" 2>/dev/null || echo "{}")
  echo "$stats" | grep -q "web_requests" && echo "$stats" | grep -q "last_web_time_ms" && echo "OK" || { echo "FAIL"; exit 1; }
  echo "Test 9: Run web demo updates metrics..."
  curl -sf "$BASE/run_demo.php?type=web" > /dev/null
  stats2=$(curl -sf "$BASE/dashboard.php?json=1")
  wr=$(echo "$stats2" | grep -o '"web_requests":[0-9]*' | cut -d: -f2)
  [ -n "$wr" ] && [ "$wr" -ge 1 ] && echo "OK (web_requests=$wr)" || { echo "FAIL"; exit 1; }
  echo "Test 10: Run CLI demo updates metrics..."
  curl -sf "$BASE/run_demo.php?type=cli" > /dev/null
  stats3=$(curl -sf "$BASE/dashboard.php?json=1")
  cr=$(echo "$stats3" | grep -o '"cli_runs":[0-9]*' | cut -d: -f2)
  [ -n "$cr" ] && [ "$cr" -ge 1 ] && echo "OK (cli_runs=$cr)" || { echo "FAIL"; exit 1; }
fi
echo "All tests passed."
