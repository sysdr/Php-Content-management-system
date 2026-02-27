<?php
namespace HighScaleCMS;

use PsrHttpMessage\ServerRequestInterface;
use PsrHttpMessage\UriInterface;

class Uri implements UriInterface
{
    private string $path;

    public function __construct(string $path)
    {
        $this->path = $path;
    }

    public function getPath(): string
    {
        return $this->path;
    }
}

class Request implements ServerRequestInterface
{
    private string $method;
    private UriInterface $uri;
    private array $attributes = [];

    public function __construct(string $method, string $path)
    {
        $this->method = strtoupper($method);
        $this->uri = new Uri($path);
    }

    public function getMethod(): string
    {
        return $this->method;
    }

    public function getUri(): UriInterface
    {
        return $this->uri;
    }

    public function getPath(): string
    {
        return $this->uri->getPath();
    }

    // Simplified for demo - not fully PSR-7 compliant, just the parts we need
    public function getQueryParams(): array { return []; }
    public function getParsedBody(): null|array|object { return null; }
    public function getAttributes(): array { return $this->attributes; }
    public function withAttribute(string $name, mixed $value): self { $clone = clone $this; $clone->attributes[$name] = $value; return $clone; }
}
