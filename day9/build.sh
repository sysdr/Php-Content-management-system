#!/bin/bash
# Build Day9 High-Scale CMS (FrankenPHP) Docker image
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
PROJECT_DIR="high-scale-cms"
DOCKER_IMAGE_NAME="high-scale-cms-frankenphp"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "Project not found. Run ./setup.sh first."
    exit 1
fi

if ! command -v docker &>/dev/null; then
    echo "Docker not found. Install Docker or use native PHP run only."
    exit 1
fi

# Ensure Dockerfile exists (setup creates it only when run with --docker)
if [ ! -f "$PROJECT_DIR/Dockerfile" ]; then
    echo "Creating Dockerfile..."
    cat <<'EOF' > "$PROJECT_DIR/Dockerfile"
FROM dunglas/frankenphp

WORKDIR /var/www/html

# Copy Caddyfile, application code, and data
COPY Caddyfile /etc/caddy/Caddyfile
COPY public ./public
COPY data ./data

# Expose HTTP port
EXPOSE 80
EOF
fi

cd "$PROJECT_DIR"
docker build -t "$DOCKER_IMAGE_NAME" .
echo "Build complete. Image: $DOCKER_IMAGE_NAME"
echo "Run with: ./start.sh --docker"
