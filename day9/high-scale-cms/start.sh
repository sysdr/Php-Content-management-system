#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
if [ "$1" = "--docker" ]; then
  if docker ps -q -f name=cms-frankenphp-app 2>/dev/null | grep -q .; then
    echo "Container cms-frankenphp-app already running. Use ./stop.sh first."
    exit 1
  fi
  docker run -d --name cms-frankenphp-app -p 80:80 high-scale-cms-frankenphp || { echo "Start failed. Build with: docker build -t high-scale-cms-frankenphp ."; exit 1; }
  echo "Started FrankenPHP in Docker. Dashboard: http://127.0.0.1:80/dashboard.php"
  exit 0
fi
if pgrep -f "frankenphp run" >/dev/null; then
  echo "FrankenPHP already running. Use ./stop.sh first."
  exit 1
fi
if fuser 80/tcp >/dev/null 2>&1; then
  echo "Port 80 already in use. Use ./stop.sh first."
  exit 1
fi
if [ -x "./frankenphp" ]; then
  nohup ./frankenphp run --config Caddyfile > frankenphp.log 2>&1 &
  echo $! > frankenphp.pid
  sleep 2
  if pgrep -f "frankenphp run" >/dev/null; then
    echo "Started FrankenPHP. Dashboard: http://127.0.0.1:80/dashboard.php"
  else
    echo "FrankenPHP failed. Trying PHP built-in server..."
    [ -f frankenphp.pid ] && kill $(cat frankenphp.pid) 2>/dev/null; rm -f frankenphp.pid
    PHP_BIN=""
    for p in php /usr/bin/php /usr/local/bin/php; do command -v "$p" &>/dev/null && PHP_BIN="$p" && break; done
    [ -z "$PHP_BIN" ] && PHP_BIN="php"
    if command -v "$PHP_BIN" &>/dev/null; then
      # Port 80 often requires root; use 8000 for PHP fallback
      PHP_PORT=8000
      nohup $PHP_BIN -S 0.0.0.0:$PHP_PORT -t public > frankenphp.log 2>&1 &
      echo $! > frankenphp.pid
      sleep 1
      fuser ${PHP_PORT}/tcp >/dev/null 2>&1 && echo "Started PHP server on port $PHP_PORT. Dashboard: http://127.0.0.1:$PHP_PORT/dashboard.php" || { echo "Failed to start PHP server."; exit 1; }
    else
      echo "Failed to start FrankenPHP. Check frankenphp.log"; exit 1
    fi
  fi
else
  PHP_BIN=""
  for p in php /usr/bin/php /usr/local/bin/php; do
    command -v "$p" &>/dev/null && PHP_BIN="$p" && break
  done
  [ -z "$PHP_BIN" ] && PHP_BIN="php"
  if ! command -v "$PHP_BIN" &>/dev/null; then
    echo "FrankenPHP binary not found and PHP not in PATH. Run setup.sh from day9 first or install PHP."
    exit 1
  fi
  echo "FrankenPHP binary not found. Starting PHP built-in server on port 8000..."
  nohup $PHP_BIN -S 0.0.0.0:8000 -t public > frankenphp.log 2>&1 &
  echo $! > frankenphp.pid
  sleep 1
  if fuser 8000/tcp >/dev/null 2>&1; then
    echo "Started PHP server. Dashboard: http://127.0.0.1:8000/dashboard.php"
  else
    echo "Failed to start PHP server. Check frankenphp.log"; exit 1
  fi
fi
