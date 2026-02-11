<?php
header('Content-Type: application/json; charset=utf-8');
$base = realpath(dirname(__DIR__)) ?: dirname(__DIR__);
$statsFile = $base . '/data/stats.json';
$stats = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];
$stats['demo_runs'] = 0;
$stats['requests_processed'] = 0;
$stats['last_updated'] = date('c');
@file_put_contents($statsFile, json_encode($stats), LOCK_EX);
echo json_encode(['ok' => true, 'stats' => $stats]);
