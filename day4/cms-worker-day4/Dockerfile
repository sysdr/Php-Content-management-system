FROM php:8.4-cli
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip git \
    && docker-php-ext-install sockets \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copy project files
COPY composer.json composer.lock ./
COPY .rr.yaml ./
COPY worker.php ./
COPY public/ ./public/
RUN mkdir -p data && echo '{"php_requests":0,"roadrunner_requests":0}' > data/stats.json

# Install PHP deps
RUN composer install --no-dev --no-interaction

# Download RoadRunner binary (vendor rr is PHP wrapper, we need standalone)
ARG RR_VERSION=2024.3.5
RUN cd /tmp && curl -sSL "https://github.com/roadrunner-server/roadrunner/releases/download/v${RR_VERSION}/roadrunner-${RR_VERSION}-linux-amd64.tar.gz" -o rr.tar.gz \
    && tar -xzf rr.tar.gz && (mv rr /usr/local/bin/ 2>/dev/null || mv roadrunner-*/rr /usr/local/bin/) && chmod +x /usr/local/bin/rr && rm -rf rr.tar.gz roadrunner-*

# Start script: PHP server (8000) + RoadRunner (8080)
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'php -S 0.0.0.0:8000 -t /app/public &' >> /start.sh && \
    echo 'exec rr serve -c /app/.rr.yaml' >> /start.sh && \
    chmod +x /start.sh

EXPOSE 8000 8080
CMD ["/start.sh"]
