#!/bin/bash
set -e
PHP_PORT=8000
RR_PORT=8080
BASE="http://127.0.0.1"
echo "=== Running tests ==="
echo "Test 1: PHP built-in server responds..."
curl -sf -o /dev/null -w "%{http_code}" "$BASE:$PHP_PORT/" | grep -q 200 && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 2: RoadRunner server responds..."
curl -sf -o /dev/null -w "%{http_code}" "$BASE:$RR_PORT/" | grep -q 200 && echo "OK" || { echo "FAIL"; exit 1; }
echo "Test 3: Dashboard loads..."
code=$(curl -sf -o /tmp/dashboard_day2.html -w "%{http_code}" "$BASE:$PHP_PORT/dashboard.php")
[ "$code" = "200" ] && echo "OK" || { echo "FAIL (code $code)"; exit 1; }
echo "Test 4: Dashboard shows metrics..."
grep -q "PHP built-in\|metric-php" /tmp/dashboard_day2.html && grep -q "RoadRunner\|metric-rr" /tmp/dashboard_day2.html && echo "OK" || { echo "FAIL"; exit 1; }
echo "All tests passed."
