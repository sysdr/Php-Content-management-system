<?php

namespace HighScaleCMS;

class RouteMatch
{
    public readonly mixed $handler;
    public readonly array $parameters;
    public readonly array $debug;

    public function __construct(callable $handler, array $parameters = [], array $debug = [])
    {
        $this->handler = $handler;
        $this->parameters = $parameters;
        $this->debug = $debug;
    }
}
