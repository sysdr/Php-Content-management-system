<?php

// Load PSR interfaces and implementation in dependency order
require __DIR__ . '/../src/MessageInterface.php';
require __DIR__ . '/../src/UriInterface.php';
require __DIR__ . '/../src/RequestInterface.php';
require __DIR__ . '/../src/ServerRequestInterface.php';
require __DIR__ . '/../src/Request.php';
require __DIR__ . '/../src/App.php';

use HighScaleCMS\App;
use HighScaleCMS\Request;

// Create a simple request object from global PHP variables
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);

$request = new Request($method, $path);

$app = new App();
$response = $app->handle($request);
if (str_starts_with(trim($response), '<!DOCTYPE') || str_starts_with(trim($response), '<html')) {
    header('Content-Type: text/html; charset=utf-8');
}
echo $response;

