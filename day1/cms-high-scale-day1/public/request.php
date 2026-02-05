<?php
/**
 * Same-origin proxy for dashboard operations.
 * Forwards requests to RoadRunner (:8080) so the browser does not make
 * cross-origin requests (avoids CORS). PHP requests go directly to / (same origin).
 */
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

$target = isset($_GET['target']) ? (string) $_GET['target'] : '';
if ($target !== 'rr') {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => 'Use target=rr to proxy to RoadRunner']);
    exit;
}

$url = 'http://127.0.0.1:8080/';

$ctx = stream_context_create([
    'http' => [
        'timeout' => 5,
        'ignore_errors' => true,
    ],
]);

$body = @file_get_contents($url, false, $ctx);
if ($body === false) {
    http_response_code(502);
    echo json_encode(['ok' => false, 'error' => 'Backend request failed']);
    exit;
}

echo json_encode(['ok' => true, 'target' => $target]);
