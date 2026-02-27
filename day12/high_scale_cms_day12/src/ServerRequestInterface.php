<?php
namespace PsrHttpMessage;

interface ServerRequestInterface extends RequestInterface
{
    public function getQueryParams(): array;
    public function getParsedBody(): null|array|object;
    public function getAttributes(): array;
    public function withAttribute(string $name, mixed $value): self;
    public function getUri(): UriInterface;
    public function getMethod(): string;
    public function getPath(): string; // Custom for easy access in demo
}
