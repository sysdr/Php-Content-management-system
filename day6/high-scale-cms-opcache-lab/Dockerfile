FROM php:8.3-fpm-alpine

# Install necessary extensions, including opcache
RUN docker-php-ext-install opcache
RUN apk add --no-cache bash

# Set working directory for web and cli
WORKDIR /var/www/html
