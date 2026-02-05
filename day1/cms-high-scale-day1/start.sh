#!/bin/bash
cd "$(dirname "$0")" || exit 1
# Avoid duplicate servers
for port in 8000 8080; do
  if fuser "$port/tcp" >/dev/null 2>&1; then echo "Port $port already in use; run ./stop.sh first."; exit 1; fi
done
php -S 127.0.0.1:8000 -t public > /dev/null 2>&1 &
RR_BIN="./rr"; [ -x "$RR_BIN" ] || RR_BIN="./vendor/bin/rr"
$RR_BIN serve -c .rr.yaml > /dev/null 2>&1 &
echo "Started PHP server (port 8000) and RoadRunner (port 8080). Dashboard: http://127.0.0.1:8000/dashboard.php"
