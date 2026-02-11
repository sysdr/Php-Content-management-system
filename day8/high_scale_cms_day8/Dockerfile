FROM php:8.2-cli-alpine

RUN apk add --no-cache php82-pecl-pcntl && rm -rf /var/cache/apk/*

WORKDIR /app

COPY worker.php .

CMD ["php", "worker.php"]
