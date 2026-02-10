<?php
header('Content-Type: application/json; charset=utf-8');
$base = realpath(dirname(__DIR__)) ?: dirname(__DIR__);
$statsFile = $base . '/data/stats.json';
$stats = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];
$logFile = $base . '/logs/resource_events.log';
@unlink($logFile);
$cmd = 'cd ' . escapeshellarg($base) . ' && php ' . escapeshellarg($base . '/src/App.php') . ' 2>&1';
$output = (string)shell_exec($cmd);
$stats['request_runs'] = ($stats['request_runs'] ?? 0) + 1;
$stats['total_requests_simulated'] = ($stats['request_runs'] ?? 0) * 3;
$destructCount = 0;
if (is_file($logFile)) {
    $destructCount = (int)preg_match_all('/automatically released via __destruct/', file_get_contents($logFile));
}
$stats['last_destruct_calls'] = $destructCount;
@file_put_contents($statsFile, json_encode($stats), LOCK_EX);
echo json_encode(['ok' => true, 'stats' => $stats]);
