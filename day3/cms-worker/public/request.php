<?php
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
$target = isset($_GET['target']) ? (string)$_GET['target'] : '';
if ($target !== 'rr') {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => 'Use target=rr']);
    exit;
}
$ctx = stream_context_create(['http' => ['timeout' => 5, 'ignore_errors' => true]]);
$body = @file_get_contents('http://127.0.0.1:8080/', false, $ctx);
if ($body === false) {
    http_response_code(502);
    echo json_encode(['ok' => false, 'error' => 'Backend request failed']);
    exit;
}
echo json_encode(['ok' => true, 'target' => $target]);
