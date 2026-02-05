FROM php:8.2-cli-alpine
RUN apk add --no-cache curl tar
WORKDIR /app
ARG RR_VERSION=2.14.2
RUN curl -sSL "https://github.com/spiral/roadrunner/releases/download/v${RR_VERSION}/rr-${RR_VERSION}-linux-amd64.tar.gz" | tar -xz rr && chmod +x rr
COPY . .
EXPOSE 8080
CMD ["./rr", "serve", "-c", "rr.yaml"]
