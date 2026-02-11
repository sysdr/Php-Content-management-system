#!/bin/bash
# Build Day10 High-Scale PHP CMS (RoadRunner Kernel Registry) — Docker image or ensure project is built
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
PROJECT_DIR="HighScalePHPCMS"
DOCKER_IMAGE_NAME="high-scale-cms-kernel-registry"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "Project not found. Run ./setup.sh first."
    exit 1
fi

# Optional: build Docker image if Docker is available
if command -v docker &>/dev/null; then
    if [ ! -f "$PROJECT_DIR/Dockerfile" ]; then
        echo "Creating Dockerfile..."
        cat <<'EOF' > "$PROJECT_DIR/Dockerfile"
FROM php:8.2-cli-alpine

WORKDIR /app

RUN apk add --no-cache git curl

COPY --from=composer/composer:latest-bin /composer /usr/bin/composer

COPY . .

RUN composer install --no-dev --optimize-autoloader

RUN curl -sfL "https://github.com/roadrunner-server/roadrunner/releases/latest/download/rr-linux-amd64" -o rr && chmod +x rr || true

EXPOSE 8080

CMD ["./rr", "serve", "-c", "roadrunner.yaml"]
EOF
    fi
    cd "$PROJECT_DIR"
    if docker build -t "$DOCKER_IMAGE_NAME" . 2>/dev/null; then
        echo "Build complete. Image: $DOCKER_IMAGE_NAME"
        echo "Run with: docker run -d -p 8080:8080 --name ${DOCKER_IMAGE_NAME}-container $DOCKER_IMAGE_NAME"
    else
        echo "Docker build failed (e.g. credentials/network). Skipping image build."
    fi
fi

# Ensure PHP deps are present (whether or not Docker was used)
cd "$SCRIPT_DIR/$PROJECT_DIR"
if [ -f composer.json ] && [ ! -d vendor ]; then
    echo "Installing PHP dependencies..."
    (command -v composer &>/dev/null && composer install) || php composer.phar install 2>/dev/null || true
fi

# If Docker build was skipped or failed, still report success for local build
if ! docker images -q "$DOCKER_IMAGE_NAME" 2>/dev/null | grep -q .; then
    echo "Run ./start.sh from $PROJECT_DIR to start (RoadRunner + dashboard)."
fi
