#!/bin/bash
set -e
cd "$(dirname "$0")/.." || exit 1
PHP_PORT=8000
RR_PORT=8080
BASE="http://127.0.0.1"
echo "=== Running Day3 tests ==="
echo "Test 1: PHP built-in server responds..."
curl -sf -o /dev/null -w "%{http_code}" "$BASE:$PHP_PORT/" | grep -q 200 && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 2: RoadRunner server responds..."
curl -sf -o /dev/null -w "%{http_code}" "$BASE:$RR_PORT/" | grep -q 200 && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 3: Dashboard loads..."
code=$(curl -sf -o /tmp/dashboard_day3.html -w "%{http_code}" "$BASE:$PHP_PORT/dashboard.php")
[ "$code" = "200" ] && echo "OK" || { echo "FAIL (code $code)"; exit 1; }
echo "Test 4: Dashboard shows metrics..."
grep -q "PHP built-in\|metric-php" /tmp/dashboard_day3.html && grep -q "RoadRunner\|metric-rr" /tmp/dashboard_day3.html && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 5: JSON stats endpoint..."
stats=$(curl -sf "$BASE:$PHP_PORT/dashboard.php?json=1")
echo "$stats" | grep -q "php_requests" && echo "$stats" | grep -q "roadrunner_requests" && echo "OK" || { echo "FAIL"; exit 1; }
echo "All tests passed."
