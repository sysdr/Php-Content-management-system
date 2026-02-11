<?php
header('Content-Type: application/json; charset=utf-8');
$base = realpath(dirname(__DIR__)) ?: dirname(__DIR__);
$statsFile = $base . '/data/stats.json';
$stats = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];
$workerUrl = 'http://127.0.0.1:8080';
$numRequests = 3;
$requestsProcessed = 0;
for ($i = 0; $i < $numRequests; $i++) {
    $ctx = stream_context_create(['http' => ['timeout' => 3]]);
    $r = @file_get_contents($workerUrl . '/', false, $ctx);
    if ($r !== false) $requestsProcessed++;
}
$stats['demo_runs'] = ($stats['demo_runs'] ?? 0) + 1;
$stats['requests_processed'] = ($stats['requests_processed'] ?? 0) + $requestsProcessed;
$stats['last_updated'] = date('c');
@file_put_contents($statsFile, json_encode($stats), LOCK_EX);
echo json_encode(['ok' => true, 'stats' => $stats]);
