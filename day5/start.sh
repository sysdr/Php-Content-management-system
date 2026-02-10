#!/bin/bash
# Start Day5 PHP CMS server (runs the built-in PHP server for the dashboard)
cd "$(dirname "$0")"
if [ ! -d "php_cms_leak_detection" ]; then
    echo "Project not found. Run ./setup.sh first."
    exit 1
fi
exec ./php_cms_leak_detection/start.sh
