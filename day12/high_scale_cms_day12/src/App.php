<?php

namespace HighScaleCMS;

use PsrHttpMessage\ServerRequestInterface;

// Simple Autoloader for our demo
spl_autoload_register(function ($class) {
    $prefix = 'HighScaleCMS\\';
    $base_dir = __DIR__ . '/';
    $len = strlen($prefix);
    if (strncmp($prefix, $class, $len) !== 0) {
        return;
    }
    $relative_class = substr($class, $len);
    $file = $base_dir . str_replace('\\', '/', $relative_class) . '.php';
    if (file_exists($file)) {
        require $file;
    }
});

class App
{
    private Router $router;

    /**
     * Shared HTML layout with nav so all dashboard tabs work in the browser.
     */
    private static function layout(string $pageTitle, string $bodyContent, string $routeLabel): string
    {
        $title = htmlspecialchars($pageTitle, ENT_QUOTES, 'UTF-8');
        $body = nl2br(htmlspecialchars($bodyContent, ENT_QUOTES, 'UTF-8'));
        $route = htmlspecialchars($routeLabel, ENT_QUOTES, 'UTF-8');
        return '<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>' . $title . ' – Day 12 CMS</title>
<style>
*{box-sizing:border-box} body{margin:0;font-family:system-ui,sans-serif;background:#0f172a;color:#e2e8f0;min-height:100vh;display:flex;flex-direction:column}
.nav{background:#1e293b;padding:12px 20px;display:flex;gap:16px;align-items:center;flex-wrap:wrap}
.nav a{color:#38bdf8;text-decoration:none} .nav a:hover{text-decoration:underline}
.main{flex:1;padding:24px;max-width:1100px;margin:0 auto;width:100%}
h1{margin:0 0 8px;font-size:1.5rem;font-weight:600}
.foot{margin-top:24px;font-size:0.85rem;color:#64748b}
</style>
</head>
<body>
<nav class="nav">
  <a href="/">Home</a>
  <a href="/admin/dashboard">Dashboard</a>
  <a href="/admin/settings/general">Settings</a>
  <a href="/users">Users</a>
  <a href="/posts">Posts</a>
</nav>
<main class="main">
  <h1>' . $title . '</h1>
  <p>' . $body . '</p>
  <p class="foot">Route: ' . $route . '</p>
</main>
</body>
</html>';
    }

    public function __construct()
    {
        $this->router = new Router();
        $this->registerRoutes();
    }

    private function registerRoutes(): void
    {
        // Define handlers as simple closures for this demo
        $userListHandler = function (ServerRequestInterface $request, array $params) {
            $body = "User list. Params: " . json_encode($params);
            return self::layout('Users', $body, '/users');
        };
        $userProfileHandler = function (ServerRequestInterface $request, array $params) {
            $body = "User profile for ID " . ($params['id'] ?? 'N/A') . ". Params: " . json_encode($params);
            return self::layout('User profile', $body, '/users/{id}');
        };
        $createUserHandler = function (ServerRequestInterface $request, array $params) {
            $body = "Create new user. Params: " . json_encode($params);
            return self::layout('Create user', $body, 'POST /users');
        };
        $postListHandler = function (ServerRequestInterface $request, array $params) {
            $body = "Post list. Params: " . json_encode($params);
            return self::layout('Posts', $body, '/posts');
        };
        $postDetailHandler = function (ServerRequestInterface $request, array $params) {
            $body = "Post detail for slug '" . ($params['slug'] ?? 'N/A') . "'. Params: " . json_encode($params);
            return self::layout('Post', $body, '/posts/{slug}');
        };
        $homepageHandler = function (ServerRequestInterface $request, array $params) {
            $body = "Welcome to the CMS homepage! Params: " . json_encode($params);
            return self::layout('Home', $body, '/');
        };
        $adminDashboardHandler = function (ServerRequestInterface $request, array $params) {
            $attributes = method_exists($request, 'getAttributes')
                ? $request->getAttributes()
                : [];
            $debug = $attributes['router_debug'] ?? [
                'method' => $request->getMethod(),
                'path' => $request->getUri()->getPath(),
                'parameters' => $params,
                'steps' => [],
                'allowed_methods' => [],
                'route_count' => null,
                'handler_string' => 'Closure',
            ];

            $paramsJson = json_encode($debug['parameters'] ?? $params);
            $steps = $debug['steps'] ?? [];
            $routeCount = $debug['route_count'] ?? null;
            $handlerString = $debug['handler_string'] ?? 'Closure';

            $stepsHtml = '';
            foreach ($steps as $step) {
                $segment = htmlspecialchars((string) ($step['segment'] ?? ''), ENT_QUOTES, 'UTF-8');
                $matchType = htmlspecialchars((string) ($step['match_type'] ?? ''), ENT_QUOTES, 'UTF-8');
                $paramName = htmlspecialchars((string) ($step['parameter_name'] ?? ''), ENT_QUOTES, 'UTF-8');

                $stepsHtml .= sprintf(
                    '<tr><td><code>%s</code></td><td>%s</td><td>%s</td></tr>',
                    $segment,
                    $matchType,
                    $paramName
                );
            }

            $routeCountHtml = $routeCount !== null
                ? (int) $routeCount
                : 'n/a';

            $method = htmlspecialchars($debug['method'] ?? $request->getMethod(), ENT_QUOTES, 'UTF-8');
            $path = htmlspecialchars($debug['path'] ?? $request->getUri()->getPath(), ENT_QUOTES, 'UTF-8');
            $handlerEsc = htmlspecialchars($handlerString, ENT_QUOTES, 'UTF-8');
            $paramsJsonEsc = htmlspecialchars($paramsJson, ENT_QUOTES, 'UTF-8');

            return '<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Admin Dashboard – Day 12 CMS</title>
<style>
*{box-sizing:border-box} body{margin:0;font-family:system-ui,sans-serif;background:#0f172a;color:#e2e8f0;min-height:100vh;display:flex;flex-direction:column}
.nav{background:#1e293b;padding:12px 20px;display:flex;gap:16px;align-items:center;flex-wrap:wrap}
.nav a{color:#38bdf8;text-decoration:none} .nav a:hover{text-decoration:underline}
.main{flex:1;padding:24px;max-width:1100px;margin:0 auto;width:100%}
h1{margin:0 0 8px;font-size:1.5rem;font-weight:600}
.cards{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:16px;margin-top:20px}
.card{background:#1e293b;border-radius:8px;padding:20px;border:1px solid #334155}
.card h2{font-size:1rem;margin:0 0 8px;color:#94a3b8}
.card p{margin:0;font-size:0.9rem;color:#cbd5e1}
.foot{margin-top:24px;font-size:0.85rem;color:#64748b}
.debug{margin-top:32px;padding:20px;border-radius:8px;background:#020617;border:1px solid #1e293b}
.debug h2{margin-top:0;font-size:1.1rem;color:#e5e7eb}
.debug table{width:100%;border-collapse:collapse;margin-top:12px;font-size:0.85rem}
.debug th,.debug td{border:1px solid #1f2937;padding:6px 8px;text-align:left}
.debug th{background:#111827;color:#e5e7eb}
code{font-family:ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;font-size:0.85em}
</style>
</head>
<body>
<nav class="nav">
  <a href="/">Home</a>
  <a href="/admin/dashboard">Dashboard</a>
  <a href="/admin/settings/general">Settings</a>
  <a href="/users">Users</a>
  <a href="/posts">Posts</a>
</nav>
<main class="main">
  <h1>Admin Dashboard</h1>
  <p>Day 12 CMS – Prefix-Tree Router.</p>
  <div class="cards">
    <div class="card"><h2>Content</h2><p>Manage posts and pages</p></div>
    <div class="card"><h2>Users</h2><p>User list and profiles</p></div>
    <div class="card"><h2>Settings</h2><p>Admin settings by tab</p></div>
  </div>

  <section class="debug">
    <h2>Router Debug Panel</h2>
    <p><strong>HTTP Method:</strong> <code>' . $method . '</code></p>
    <p><strong>Request URI:</strong> <code>' . $path . '</code></p>
    <p><strong>Matched Handler:</strong> <code>' . $handlerEsc . '</code></p>
    <p><strong>Parameters:</strong> <code>' . $paramsJsonEsc . '</code></p>
    <p><strong>Total Registered Routes:</strong> <code>' . $routeCountHtml . '</code></p>

    <h3>Segment Match Trace</h3>
    <table>
      <thead>
        <tr><th>Segment</th><th>Match Type</th><th>Parameter Name</th></tr>
      </thead>
      <tbody>' . $stepsHtml . '</tbody>
    </table>
  </section>

  <p class="foot">Route: GET /admin/dashboard</p>
</main>
</body>
</html>';
        };
        $adminSettingsHandler = function (ServerRequestInterface $request, array $params) {
            $body = "Admin settings for tab '" . ($params['tab'] ?? 'N/A') . "'. Params: " . json_encode($params);
            return self::layout('Admin settings', $body, '/admin/settings/{tab}');
        };

        // Register routes
        $this->router->addRoute('GET', '/', $homepageHandler);
        $this->router->addRoute('GET', '/users', $userListHandler);
        $this->router->addRoute('GET', '/users/{id}', $userProfileHandler);
        $this->router->addRoute('POST', '/users', $createUserHandler);
        $this->router->addRoute('GET', '/posts', $postListHandler);
        $this->router->addRoute('GET', '/posts/{slug}', $postDetailHandler);
        $this->router->addRoute('GET', '/admin/dashboard', $adminDashboardHandler);
        $this->router->addRoute('GET', '/admin/settings/{tab}', $adminSettingsHandler);

        if (php_sapi_name() === 'cli') {
            echo "Registered Routes:\n";
            echo "  - GET /\n";
            echo "  - GET /users\n";
            echo "  - GET /users/{id}\n";
            echo "  - POST /users\n";
            echo "  - GET /posts\n";
            echo "  - GET /posts/{slug}\n";
            echo "  - GET /admin/dashboard\n";
            echo "  - GET /admin/settings/{tab}\n";
            echo "---------------------------------------------------\n";
        }
    }

    public function handle(ServerRequestInterface $request): string
    {
        try {
            $routeMatch = $this->router->match($request);
            $handler = $routeMatch->handler;
            $parameters = $routeMatch->parameters;
            $debug = $routeMatch->debug ?? [];

            if ($request instanceof Request) {
                $request = $request->withAttribute('router_debug', $debug);
            }

            return $handler($request, $parameters);
        } catch (MethodNotAllowedException $e) {
            if (php_sapi_name() === 'cli') {
                return '405 Method Not Allowed: ' . $e->getMessage();
            }
            return self::layout(
                '405 Method Not Allowed',
                $e->getMessage() . ' Allowed: ' . implode(', ', $e->getAllowedMethods()),
                '405'
            );
        } catch (RouteNotFoundException $e) {
            if (php_sapi_name() === 'cli') {
                return '404 Not Found: ' . $e->getMessage();
            }
            return self::layout('404 Not Found', $e->getMessage(), '404');
        } catch (\Exception $e) {
            if (php_sapi_name() === 'cli') {
                return '500 Server Error: ' . $e->getMessage();
            }
            return self::layout('500 Server Error', $e->getMessage(), '500');
        }
    }

    public function runCliDemo(array $requests): void
    {
        echo "\n>>> [4/5] Running CLI Demo...\n";
        foreach ($requests as $req) {
            list($method, $path) = $req;
            $request = new Request($method, $path);
            echo "  Matching: {$method} {$path}\n";
            $response = $this->handle($request);
            echo "  Result: {$response}\n";
            echo "---------------------------------------------------\n";
        }
    }
}
