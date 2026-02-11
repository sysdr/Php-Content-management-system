<?php
header('Content-Type: application/json; charset=utf-8');
$base = realpath(dirname(__DIR__)) ?: dirname(__DIR__);
$statsFile = $base . '/data/stats.json';
$stats = json_decode(@file_get_contents($statsFile) ?: '{}', true) ?: [];
$logFile = $base . '/data/worker_demo.log';
$workerScript = $base . '/worker.php';
if (!is_file($workerScript)) {
    echo json_encode(['ok' => false, 'error' => 'worker.php not found']);
    exit;
}
@unlink($logFile);
$baseEsc = escapeshellarg($base);
$workerEsc = escapeshellarg($workerScript);
$logEsc = escapeshellarg($logFile);
$cmd = "cd $baseEsc && php $workerEsc > $logEsc 2>&1 & WPID=\$!; sleep 5; kill \$WPID 2>/dev/null; wait \$WPID 2>/dev/null; cat $logEsc";
$output = (string)shell_exec($cmd);
@file_put_contents($logFile, $output);
$requestsProcessed = 0;
if (is_file($logFile)) {
    $requestsProcessed = (int)preg_match_all('/Processing request #\d+/', file_get_contents($logFile));
}
$stats['demo_runs'] = ($stats['demo_runs'] ?? 0) + 1;
$stats['native_cycles'] = ($stats['native_cycles'] ?? 0) + 1;
$stats['requests_processed'] = ($stats['requests_processed'] ?? 0) + $requestsProcessed;
@file_put_contents($statsFile, json_encode($stats), LOCK_EX);
echo json_encode(['ok' => true, 'stats' => $stats]);
