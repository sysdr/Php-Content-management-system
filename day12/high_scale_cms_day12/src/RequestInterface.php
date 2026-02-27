<?php
namespace PsrHttpMessage;

interface RequestInterface extends MessageInterface
{
    public function getUri(): UriInterface;
    public function getMethod(): string;
}
