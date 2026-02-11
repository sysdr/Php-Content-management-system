<?php
header('Content-Type: application/json; charset=utf-8');
$ctx = stream_context_create(['http' => ['timeout' => 2]]);
$r = @file_get_contents('http://127.0.0.1:8080/', false, $ctx);
echo json_encode(['ok' => $r !== false, 'worker' => '127.0.0.1:8080']);
