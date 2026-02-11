FROM php:8.2-cli-alpine

WORKDIR /app

RUN apk add --no-cache git curl

COPY --from=composer/composer:latest-bin /composer /usr/bin/composer

COPY . .

RUN composer install --no-dev --optimize-autoloader

RUN curl -sfL "https://github.com/roadrunner-server/roadrunner/releases/latest/download/rr-linux-amd64" -o rr && chmod +x rr || true

EXPOSE 8080

CMD ["./rr", "serve", "-c", "roadrunner.yaml"]
