<?php

namespace HighScaleCMS;

class TrieNode
{
    /** @var array<string, TrieNode> Child nodes, keyed by static segment or a special key for parameter nodes */
    public array $children = [];

    /** @var string|null The name of the parameter if this node represents a dynamic segment (e.g., 'id', 'slug') */
    public ?string $paramName = null;

    /** @var array<string, callable> Mapped HTTP methods to handlers for this node */
    public array $handlers = [];

    /**
     * Constructor for a TrieNode.
     *
     * @param string|null $paramName The name of the parameter if this node represents a dynamic segment.
     */
    public function __construct(?string $paramName = null)
    {
        $this->paramName = $paramName;
    }

    /**
     * Checks if this node represents an end of a valid route for a given HTTP method.
     */
    public function hasHandler(string $method): bool
    {
        return isset($this->handlers[$method]);
    }

    /**
     * Retrieves the handler for a given HTTP method.
     */
    public function getHandler(string $method): ?callable
    {
        return $this->handlers[$method] ?? null;
    }
}
