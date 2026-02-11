#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
if fuser 8080/tcp >/dev/null 2>&1; then
  echo "Port 8080 already in use (RoadRunner may be running). Use ./stop.sh first or skip start."
  exit 1
fi
if fuser 8081/tcp >/dev/null 2>&1; then
  echo "Port 8081 already in use (dashboard server). Use ./stop.sh first."
  exit 1
fi
RR_BIN="../rr"
if [ -x "$RR_BIN" ]; then
  nohup "$RR_BIN" serve -c roadrunner.yaml > roadrunner_output.log 2>&1 &
  echo $! > roadrunner.pid
  echo "Started RoadRunner on :8080 (PID $(cat roadrunner.pid))."
  sleep 2
else
  echo "RoadRunner binary not found at $RR_BIN — starting dashboard only (worker on :8080 will be unavailable)."
fi
PHP_BIN=""
for p in php /usr/bin/php; do command -v "$p" &>/dev/null && PHP_BIN="$p" && break; done
[ -z "$PHP_BIN" ] && PHP_BIN="php"
nohup "$PHP_BIN" -S 0.0.0.0:8081 -t public > php_dashboard.log 2>&1 &
echo $! > php_dashboard.pid
echo "Started dashboard on :8081. Dashboard: http://127.0.0.1:8081/dashboard.php"
