<?php
// Router for PHP built-in server: handle /favicon.ico to avoid 404, pass through everything else.
$uri = $_SERVER['REQUEST_URI'] ?? '';
$path = parse_url($uri, PHP_URL_PATH);
if ($path === '/favicon.ico' || $path === 'favicon.ico') {
    header('HTTP/1.1 204 No Content');
    header('Content-Length: 0');
    return true;
}
return false;
