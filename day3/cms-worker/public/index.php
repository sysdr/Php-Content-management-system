<?php
$statsFile = dirname(__DIR__) . '/data/stats.json';
$data = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];
$data['php_requests'] = ($data['php_requests'] ?? 0) + 1;
@file_put_contents($statsFile, json_encode($data), LOCK_EX);
header('Content-Type: text/plain');
echo "Hello from high-scale CMS! Request processed at " . date('Y-m-d H:i:s') . "\n";
