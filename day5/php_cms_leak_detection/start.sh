#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
PHP_BIN=""
for p in php /usr/bin/php /usr/local/bin/php; do
  if command -v "$p" &>/dev/null && "$p" -v &>/dev/null 2>&1; then PHP_BIN="$p"; break; fi
done
[ -z "$PHP_BIN" ] && command -v php &>/dev/null && PHP_BIN="php"
if [ -z "$PHP_BIN" ]; then
  echo "PHP not found. Please install PHP or add it to PATH."
  exit 1
fi
if fuser "8000/tcp" >/dev/null 2>&1; then
  echo "Port 8000 already in use. Run stop.sh first or use another port."
  exit 1
fi
# Bind to 0.0.0.0 so the dashboard is reachable from browser (e.g. Windows when server runs in WSL)
# Use router.php to handle /favicon.ico (204) and avoid 404
nohup $PHP_BIN -S 0.0.0.0:8000 -t public public/router.php > /dev/null 2>&1 &
sleep 1
if fuser "8000/tcp" >/dev/null 2>&1; then
  echo "Started PHP server on port 8000."
  echo "  Dashboard: http://127.0.0.1:8000/dashboard.php"
  echo "  (If using WSL, try http://localhost:8000/dashboard.php from your browser)"
else
  echo "Failed to start PHP server on port 8000. Check that PHP is installed and port is free."
  exit 1
fi
