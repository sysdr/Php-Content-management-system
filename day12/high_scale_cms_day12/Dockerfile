FROM php:8.2-fpm-alpine

WORKDIR /var/www/html

# Install system dependencies (optional; nginx runs in separate container)
RUN apk add --no-cache nginx || true

# Copy application files
COPY . .

# Expose port 9000 for FPM
EXPOSE 9000

CMD ["php-fpm"]
