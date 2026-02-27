<?php
declare(strict_types=1);

require_once __DIR__ . '/../vendor/autoload.php';

use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;
use GuzzleHttp\Psr7\ServerRequest;
use GuzzleHttp\Psr7\Response;
use GuzzleHttp\Psr7\Utils;

class FinalHandler implements RequestHandlerInterface
{
    public function handle(ServerRequestInterface $request): ResponseInterface
    {
        $body = Utils::streamFor("Hello from the High-Scale CMS! Your request URI: " . $request->getUri()->getPath());
        $response = (new Response(200, [], $body))->withHeader('Content-Type', 'text/plain');
        return $response;
    }
}

class AddCustomHeaderMiddleware implements MiddlewareInterface
{
    public function process(ServerRequestInterface $request, RequestHandlerInterface $handler): ResponseInterface
    {
        $response = $handler->handle($request);
        return $response->withHeader('X-Processed-By', 'HighScaleCMS-Day11')
                        ->withHeader('X-Request-Method', $request->getMethod());
    }
}

$request = ServerRequest::fromGlobals();
$middleware = new AddCustomHeaderMiddleware();
$finalHandler = new FinalHandler();
$response = $middleware->process($request, $finalHandler);

http_response_code($response->getStatusCode());
foreach ($response->getHeaders() as $name => $values) {
    foreach ($values as $value) {
        header(sprintf('%s: %s', $name, $value), false);
    }
}
echo $response->getBody();
