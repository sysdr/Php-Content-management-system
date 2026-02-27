<?php

namespace HighScaleCMS;

use PsrHttpMessage\ServerRequestInterface;

class Router
{
    private TrieNode $root;
    private int $routeCount = 0;

    public function __construct()
    {
        $this->root = new TrieNode();
    }

    /**
     * Adds a route to the router's prefix tree.
     *
     * @param string $method The HTTP method (e.g., 'GET', 'POST').
     * @param string $path The URI path (e.g., '/users/{id}/profile').
     * @param callable $handler The callable handler for this route.
     */
    public function addRoute(string $method, string $path, callable $handler): void
    {
        $segments = explode('/', trim($path, '/'));
        $currentNode = $this->root;
        $normalizedMethod = strtoupper($method);

        foreach ($segments as $segment) {
            if (empty($segment)) {
                continue; // Skip empty segments from '/foo//bar' or leading/trailing slashes
            }

            if (preg_match('/^{([a-zA-Z0-9_]+)}$/', $segment, $matches)) {
                // This is a parameter segment, e.g., {id}
                $paramName = $matches[1];
                $paramKey = '__PARAM__'; // Special key for parameter children

                // Ensure only one parameter child per node (for simplicity in this lesson)
                if (!isset($currentNode->children[$paramKey])) {
                    $currentNode->children[$paramKey] = new TrieNode($paramName);
                } else if ($currentNode->children[$paramKey]->paramName !== $paramName) {
                    // This indicates a routing conflict if different parameter names are used at the same level
                    // For this lesson, we'll assume consistent parameter names or that this scenario is avoided.
                    // In a real system, you'd handle this more robustly.
                }
                $currentNode = $currentNode->children[$paramKey];
            } else {
                // This is a static segment
                if (!isset($currentNode->children[$segment])) {
                    $currentNode->children[$segment] = new TrieNode();
                }
                $currentNode = $currentNode->children[$segment];
            }
        }

        // Store the handler at the end of the route path
        if (!isset($currentNode->handlers[$normalizedMethod])) {
            $this->routeCount++;
        }

        $currentNode->handlers[$normalizedMethod] = $handler;
    }

    /**
     * Matches a PSR-7 request to a registered route.
     *
     * @param ServerRequestInterface $request The incoming PSR-7 request.
     * @return RouteMatch A RouteMatch object containing handler and parameters.
     * @throws RouteNotFoundException If no matching route is found.
     */
    public function match(ServerRequestInterface $request): RouteMatch
    {
        $method = strtoupper($request->getMethod());
        $path = $request->getUri()->getPath();
        $segments = explode('/', trim($path, '/'));
        $currentNode = $this->root;
        $parameters = [];
        $steps = [];

        // Handle root path explicitly
        if ($path === '' || $path === '/') {
            $allowedMethods = array_keys($currentNode->handlers);

            if ($currentNode->hasHandler($method)) {
                $handler = $currentNode->getHandler($method);
                $debug = [
                    'method' => $method,
                    'path' => '/',
                    'parameters' => [],
                    'steps' => [],
                    'allowed_methods' => $allowedMethods,
                    'route_count' => $this->routeCount,
                    'handler_string' => $this->describeHandler($handler),
                ];

                return new RouteMatch($handler, [], $debug);
            }

            if (!empty($allowedMethods)) {
                throw new MethodNotAllowedException(
                    sprintf(
                        "Method '%s' not allowed for '%s'. Allowed: %s",
                        $method,
                        '/',
                        implode(', ', $allowedMethods)
                    ),
                    $allowedMethods
                );
            }

            throw new RouteNotFoundException("No route matching '{$method} /' found.");
        }

        foreach ($segments as $segment) {
            if ($segment === '') {
                continue;
            }

            $step = [
                'segment' => $segment,
                'match_type' => null,
                'parameter_name' => null,
            ];

            $foundChild = null;

            // 1. Prioritize static match
            if (isset($currentNode->children[$segment])) {
                $foundChild = $currentNode->children[$segment];
                $step['match_type'] = 'static';
            } elseif (isset($currentNode->children['__PARAM__'])) {
                // 2. Fallback to parameter match
                $foundChild = $currentNode->children['__PARAM__'];
                $step['match_type'] = 'parameter';
                $step['parameter_name'] = $foundChild->paramName;

                if ($foundChild->paramName !== null) {
                    $parameters[$foundChild->paramName] = $segment;
                }
            }

            if ($foundChild === null) {
                $steps[] = $step;

                throw new RouteNotFoundException(
                    sprintf(
                        "No route matching '%s %s' found (segment '%s' not matched).",
                        $method,
                        $path,
                        $segment
                    )
                );
            }

            $steps[] = $step;
            $currentNode = $foundChild;
        }

        $allowedMethods = array_keys($currentNode->handlers);

        // After traversing all segments, check if a handler exists for the method
        if ($currentNode->hasHandler($method)) {
            $handler = $currentNode->getHandler($method);

            $debug = [
                'method' => $method,
                'path' => $path,
                'parameters' => $parameters,
                'steps' => $steps,
                'allowed_methods' => $allowedMethods,
                'route_count' => $this->routeCount,
                'handler_string' => $this->describeHandler($handler),
            ];

            return new RouteMatch($handler, $parameters, $debug);
        }

        if (!empty($allowedMethods)) {
            throw new MethodNotAllowedException(
                sprintf(
                    "Method '%s' not allowed for '%s'. Allowed: %s",
                    $method,
                    $path,
                    implode(', ', $allowedMethods)
                ),
                $allowedMethods
            );
        }

        throw new RouteNotFoundException(
            sprintf(
                "No route matching '%s %s' found.",
                $method,
                $path
            )
        );
    }

    /**
     * Returns the current number of registered route + method combinations.
     */
    public function getRouteCount(): int
    {
        return $this->routeCount;
    }

    /**
     * @param callable $handler
     */
    private function describeHandler(callable $handler): string
    {
        if (is_array($handler)) {
            $class = is_object($handler[0]) ? get_class($handler[0]) : (string) $handler[0];

            return $class . '::' . (string) $handler[1];
        }

        if (is_string($handler)) {
            return $handler;
        }

        if ($handler instanceof \Closure) {
            return 'Closure';
        }

        if (is_object($handler)) {
            return get_class($handler);
        }

        return 'callable';
    }
}
