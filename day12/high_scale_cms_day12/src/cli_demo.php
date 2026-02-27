<?php
require __DIR__ . '/MessageInterface.php';
require __DIR__ . '/UriInterface.php';
require __DIR__ . '/RequestInterface.php';
require __DIR__ . '/ServerRequestInterface.php';
require __DIR__ . '/Request.php';
require __DIR__ . '/App.php';

use HighScaleCMS\App;

$app = new App();
$app->runCliDemo([
    ['GET', '/'],
    ['GET', '/users'],
    ['GET', '/users/123'],
    ['GET', '/users/abc'],
    ['POST', '/users'],
    ['GET', '/posts'],
    ['GET', '/posts/my-first-blog-post'],
    ['GET', '/admin/dashboard'],
    ['GET', '/admin/settings/general'],
    ['GET', '/non-existent'],
    ['POST', '/posts/new'],
    ['GET', '/users/123/profile'],
]);
