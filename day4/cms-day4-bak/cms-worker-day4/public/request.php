<?php
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
$target = isset($_GET['target']) ? (string)$_GET['target'] : '';
if ($target !== 'rr') {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => 'Use target=rr']);
    exit;
}
$itemId = isset($_GET['item_id']) ? (string)$_GET['item_id'] : '';
$url = 'http://127.0.0.1:8080/' . ($itemId !== '' ? '?item_id=' . urlencode($itemId) : '');
$ctx = stream_context_create(['http' => ['timeout' => 5, 'ignore_errors' => true]]);
$body = @file_get_contents($url, false, $ctx);
if ($body === false) {
    http_response_code(502);
    echo json_encode(['ok' => false, 'error' => 'Backend request failed']);
    exit;
}
// When item_id is passed, return full RR response (for static state inspection)
if ($itemId !== '') {
    header('Content-Type: application/json; charset=utf-8');
    echo $body;
} else {
    echo json_encode(['ok' => true, 'target' => $target]);
}
