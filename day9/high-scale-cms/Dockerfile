FROM dunglas/frankenphp

WORKDIR /var/www/html

# Copy Caddyfile, application code, and data
COPY Caddyfile /etc/caddy/Caddyfile
COPY public ./public
COPY data ./data

# Expose HTTP port
EXPOSE 80
